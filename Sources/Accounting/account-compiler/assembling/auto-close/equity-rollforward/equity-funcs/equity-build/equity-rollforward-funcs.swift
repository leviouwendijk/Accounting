import Foundation

extension OwnerEquity.Rollforward {
    public static func allocateProfitForPeriod(
        bundle: StatementBundle,
        chart: CompiledChart,
        entities: EntityStore,
        asOf: Date,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) throws -> ProfitAllocation {
        // NI total via BusinessEntity defaults
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        let resolved = try cfg.entity.autoCloseTargets().resolve(in: ch.index!, validateWith: RGSAssembler.makeMaps(from: ch))
        let niId = resolved.ni.id
        let niTotal = bundle.income.first(where: { $0.id == niId })?.amount ?? 0

        // Posted AOW
        let aow = aeMap(bundle: bundle, code: cfg.entity.profitShareCode, maps: maps).mapValues(absD)
        let aowSum = aow.values.reduce(0, +)
        let usePosted = absD(aowSum - niTotal) <= 0.01

        // Ownership slices (ONLY for NI allocation fallback)
        let weights = Dictionary(uniqueKeysWithValues: entities.ownershipSlices(asOf: asOf).map { ($0.entityId, $0.percent) })
        let ownerIds = Set(aow.keys).union(weights.keys)

        var used: [Int: Decimal] = [:], eff: [Int: Decimal] = [:]
        if usePosted {
            for oid in ownerIds {
                let amt = aow[oid] ?? 0
                used[oid] = amt
                eff[oid] = (niTotal == 0) ? 0 : (amt / niTotal)
            }
            return .init(niTotal: niTotal, usePosted: true, usedAmounts: used, effectivePercents: eff, source: .postedAOW)
        } else {
            for oid in ownerIds {
                let p = weights[oid] ?? 0
                let amt = niTotal * p
                used[oid] = amt
                eff[oid] = p
            }
            return .init(niTotal: niTotal, usePosted: false, usedAmounts: used, effectivePercents: eff, source: .slices(asOf: asOf))
        }
    }

    public static func buildOwnerDeltas(
        bundle: StatementBundle,
        chart: CompiledChart,
        entities: EntityStore,
        asOf: Date,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) throws -> (owners: [Int], deltas: [Int: OwnerDelta], profit: ProfitAllocation) {
        let prs = aeMap(bundle: bundle, code: cfg.contribCode, maps: maps).mapValues(absD)
        let pro = aeMap(bundle: bundle, code: cfg.drawingCode, maps: maps).mapValues(absD)
        let alloc = try allocateProfitForPeriod(bundle: bundle, chart: chart, entities: entities, asOf: asOf, cfg: cfg, maps: maps)

        let owners = Set(prs.keys).union(pro.keys).union(alloc.usedAmounts.keys).sorted()
        var out: [Int: OwnerDelta] = [:]
        for oid in owners {
            out[oid] = OwnerDelta(stort: prs[oid] ?? 0, onttrek: pro[oid] ?? 0, winst: alloc.usedAmounts[oid] ?? 0)
        }
        return (owners, out, alloc)
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // Owner-tagged closing & earliest opening

    @inline(__always)
    public static func equityAnchorId(cfg: EquityRollforwardConfig, maps: ChartMaps) -> Int? {
        if let id = maps.idByCode[cfg.entity.periodOpeningRouting.equityAnchorCode] { return id }
        if let fallback = cfg.equityTotalFallback, let id = maps.idByCode[fallback] { return id }
        return nil
    }

    /// Return per-owner closing for the anchor (presentation sign if reconcilable).
    public static func equityClosingByOwner(
        bundle: StatementBundle,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) -> [Int: Decimal] {
        guard let id = equityAnchorId(cfg: cfg, maps: maps),
              let eb = bundle.entity?.byAccount,
              let m  = eb[id]
        else { return [:] }

        var assigned: [Int: Decimal] = [:]
        var unassigned: Decimal = 0
        for (eid, amt) in m {
            if let oid = eid { assigned[oid] = amt } else { unassigned = amt }
        }

        let presClose: Decimal = bundle.balance.first { $0.id == id }?.amount ?? 0
        let sumAssigned = assigned.values.reduce(0, +)
        let sumAll = sumAssigned + unassigned
        let tol: Decimal = 0.01

        if absD(sumAll + presClose) <= tol { return assigned.mapValues { -$0 } } // flip to match presentation
        if absD(sumAll - presClose) <= tol { return assigned }                    // already matches
        if absD(sumAssigned + presClose) <= tol { return assigned.mapValues { -$0 } }
        if absD(sumAssigned - presClose) <= tol { return assigned }
        return assigned // show raw owners if irreconcilable
    }

    /// Earliest BEGIN: posted opening → else backsolve from per-owner closing − delta → else 0.
    public static func buildEarliestBeginMap(
        earliest: EquityPeriod,
        chart: CompiledChart,
        entities: EntityStore,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) throws -> [Int: Decimal] {
        // 1) owner-tagged opening posted?
        if let eb = earliest.bundle.entity?.byAccount,
           let openingCode = cfg.entity.periodOpeningRouting.equityOpeningCode,
           let begId = maps.idByCode[openingCode],
           let m = eb[begId] {
            let perOwner = Dictionary(uniqueKeysWithValues: m.compactMap { (eid, amt) -> (Int, Decimal)? in
                guard let oid = eid else { return nil }
                return (oid, absD(amt)) // keep positive for begin anchor
            })
            if !perOwner.isEmpty { return perOwner }
        }

        // 2) backsolve from earliest per-owner closing
        let closingByOwner = equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps)
        if !closingByOwner.isEmpty {
            let (_, deltas, _) = try buildOwnerDeltas(bundle: earliest.bundle, chart: chart, entities: entities, asOf: earliest.asOf, cfg: cfg, maps: maps)
            let owners = Set(closingByOwner.keys).union(deltas.keys)
            var begin: [Int: Decimal] = [:]
            for oid in owners {
                let close = closingByOwner[oid] ?? 0
                let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
                begin[oid] = close - d.delta
            }
            return begin
        }

        // 3) nothing to backsolve → BEGIN = 0 per owner (owners discovered from movements)
        let (owners, _, _) = try buildOwnerDeltas(bundle: earliest.bundle, chart: chart, entities: entities, asOf: earliest.asOf, cfg: cfg, maps: maps)
        return Dictionary(uniqueKeysWithValues: owners.map { ($0, Decimal(0)) })
    }

    // Presentation totals for display (not used for per-owner math)
    public static func equityPresentationTotals(
        periodIndex i: Int,
        periods: [EquityPeriod],
        chart: CompiledChart,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) -> (opening: Decimal, closing: Decimal) {
        let eqId = equityAnchorId(cfg: cfg, maps: maps)
        let opening: Decimal = {
            if i == 0 {
                if let openingCode = cfg.entity.periodOpeningRouting.equityOpeningCode,
                   let begId = maps.idByCode[openingCode] {
                    return periods[i].bundle.balance.first { $0.id == begId }?.amount ?? 0
                } else { return 0 }
            } else {
                guard let eid = eqId else { return 0 }
                return periods[i - 1].bundle.balance.first { $0.id == eid }?.amount ?? 0
            }
        }()
        let closing: Decimal = {
            guard let eid = eqId else { return 0 }
            return periods[i].bundle.balance.first { $0.id == eid }?.amount ?? 0
        }()
        return (opening, closing)
    }
}
