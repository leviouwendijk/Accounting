import Foundation

extension OwnerEquity.Rollforward {
    // public func runOwnerEquityRollforwardHistory(
    public static func history(
        title: String = "IB equity rollforward (owner split, backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>?,
        config cfg: EquityRollforwardConfig = .init(),
        afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
    ) throws {
        // let report = try buildOwnerEquityRollforwardReport(
        let report = try Self.report(
            title: title,
            allPeriods: allPeriods,
            chart: chart,
            entities: entities,
            view: view,
            config: cfg
        )

        printHeader(report.title)

        guard !report.periods.isEmpty else {
            print("(no periods)")
            return
        }

        for msg in report.anchorMessages {
            print(msg)
        }

        let renderedPeriods: [EquityPeriod]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            renderedPeriods = Array(allPeriods[clampedLower...clampedUpper])
        } else {
            renderedPeriods = allPeriods
        }

        for (period, rendered) in zip(renderedPeriods, report.periods) {
            printPeriod(
                label: rendered.label,
                rows: rendered.rows,
                entities: entities,
                cfg: cfg
            )

            afterEachPeriod?(
                period,
                rendered.rows.owners,
                rendered.rows.deltas,
                cfg
            )
        }
    }

    // public func runOwnerEquityRollforwardHistoryAsync(
    public static func history_async(
        title: String = "IB equity rollforward (owner split, backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>?,
        config cfg: EquityRollforwardConfig = .init(),
        afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
    ) async throws {
        // let report = try await buildOwnerEquityRollforwardReportAsync(
        let report = try await report_async(
            title: title,
            allPeriods: allPeriods,
            chart: chart,
            entities: entities,
            view: view,
            config: cfg
        )

        printHeader(report.title)

        guard !report.periods.isEmpty else {
            print("(no periods)")
            return
        }

        for msg in report.anchorMessages {
            print(msg)
        }

        let renderedPeriods: [EquityPeriod]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            renderedPeriods = Array(allPeriods[clampedLower...clampedUpper])
        } else {
            renderedPeriods = allPeriods
        }

        for (period, rendered) in zip(renderedPeriods, report.periods) {
            printPeriod(
                label: rendered.label,
                rows: rendered.rows,
                entities: entities,
                cfg: cfg
            )

            afterEachPeriod?(
                period,
                rendered.rows.owners,
                rendered.rows.deltas,
                cfg
            )
        }
    }
}

extension OwnerEquity.Rollforward {
    // public func buildHistoryFromInception(
    public static func history_from_inception(
        entries: [Entry],
        endAsOf: Date,
        kind: PeriodKind,
        calendar: Calendar,
        settings: EntryCompilerSettings,
        assemble: (_ periodStart: Date, _ periodEndExcl: Date) throws -> StatementBundle
    ) throws -> [EquityPeriod] {
        // Lifetime → single bucket (inception…endAsOf)
        if kind == .lifetime {
            let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
            let start = calendar.startOfDay(for: inception)
            let endExcl = nextPeriodStart(after: periodStart(for: endAsOf, kind: .month, calendar: calendar), // put it in next midnight
                                          kind: .month, calendar: calendar)
            let b = try assemble(start, endExcl)
            return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
        }

        // Align inception to period boundary
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

        // End: make sure the last period contains endAsOf
        let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
        let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

        var out: [EquityPeriod] = []
        while curStart < hardStop {
            let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
            let endExcl = min(nextStart, hardStop)
            let bundle = try assemble(curStart, endExcl)
            out.append(.init(
                label: labelForPeriodStart(curStart, kind: kind, calendar: calendar),
                bundle: bundle,
                asOf: calendar.date(byAdding: .second, value: -1, to: endExcl) ?? endExcl
            ))
            curStart = nextStart
        }
        return out
    }

    // public func buildHistoryFromInceptionAsync(
    public static func history_from_inception_async(
        entries: [Entry],
        endAsOf: Date,
        kind: PeriodKind,
        calendar: Calendar,
        settings: EntryCompilerSettings,
        assemble_async: @escaping @Sendable (_ periodStart: Date, _ periodEndExcl: Date) async throws -> StatementBundle
    ) async throws -> [EquityPeriod] {
        // Lifetime → single bucket (inception…endAsOf)
        if kind == .lifetime {
            let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
            let start = calendar.startOfDay(for: inception)
            let endExcl = nextPeriodStart(
                after: periodStart(for: endAsOf, kind: .month, calendar: calendar),
                kind: .month,
                calendar: calendar
            )
            let b = try await assemble_async(start, endExcl)
            return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
        }

        // Non-lifetime: walk discrete periods from inception → endAsOf
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

        let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
        let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

        struct Slice {
            let index: Int
            let start: Date
            let endExcl: Date
            let label: String
            let asOf: Date
        }

        var slices: [Slice] = []
        var idx = 0

        while curStart < hardStop {
            let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
            let endExcl = min(nextStart, hardStop)

            let label = labelForPeriodStart(curStart, kind: kind, calendar: calendar)

            // as-of = last day within [curStart, endAsOf], inclusive
            let asOf: Date = {
                if endExcl > endAsOf {
                    return endAsOf
                } else {
                    // endExcl is start of next period → use previous day
                    return calendar.date(byAdding: .day, value: -1, to: endExcl) ?? endExcl
                }
            }()

            slices.append(.init(index: idx, start: curStart, endExcl: endExcl, label: label, asOf: asOf))
            curStart = nextStart
            idx += 1
        }

        if slices.isEmpty { return [] }

        // Parallel assemble per-period bundles
        var out = Array<EquityPeriod?>(repeating: nil, count: slices.count)

        try await withThrowingTaskGroup(of: (Int, EquityPeriod).self) { group in
            for s in slices {
                group.addTask { [s, assemble_async] in
                    let bundle = try await assemble_async(s.start, s.endExcl)
                    let period = EquityPeriod(label: s.label, bundle: bundle, asOf: s.asOf)
                    return (s.index, period)
                }
            }

            for try await (i, p) in group {
                out[i] = p
            }
        }

        return out.compactMap { $0 }
    }
}

// /// Print owner equity rollforward using *global* backsolve across `allPeriods`,
// /// but only render rows for indices in `view` (e.g. previous+current).
// public func runOwnerEquityRollforwardHistory(
//     title: String = "IB equity rollforward (owner split, backsolved)",
//     allPeriods: [EquityPeriod],
//     chart: CompiledChart,
//     entities: EntityStore,
//     view: ClosedRange<Int>?,                 // nil → print all
//     config cfg: EquityRollforwardConfig = .init(),
//     afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
// ) throws {
//     guard !allPeriods.isEmpty else { printHeader(title); print("(no periods)"); return }

//     let maps = ChartMaps(chart: chart)
//     let earliest = allPeriods[0]

//     // Announce anchor mode once (same logic you already have)
//     let hasPostedBegin: Bool = {
//         if let eb = earliest.bundle.entity?.byAccount,
//            let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
//            let id = maps.idByCode[code] { return eb[id] != nil }
//         return false
//     }()
//     let hasPerOwnerClosing = !equityClosingByOwner(bundle: earliest.bundle, cfg: cfg, maps: maps).isEmpty

//     printHeader(title)
//     if hasPostedBegin {
//         print("Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN.")
//     } else if hasPerOwnerClosing {
//         print("Earliest anchor: backsolved from per-owner closing − movements (no % guessing).")
//     } else {
//         print("Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner.")
//     }

//     // Compute earliest BEGIN
//     var beginByOwner = try buildEarliestBeginMap(
//         earliest: earliest, chart: chart, entities: entities, cfg: cfg, maps: maps
//     )

//     // Walk *all* periods to keep the math globally correct.
//     for (i, p) in allPeriods.enumerated() {
//         let (moveOwners, deltas, alloc) = try buildOwnerDeltas(
//             bundle: p.bundle, chart: chart, entities: entities, asOf: p.asOf, cfg: cfg, maps: maps
//         )
//         let closeOwners = Set(equityClosingByOwner(bundle: p.bundle, cfg: cfg, maps: maps).keys)
//         var owners = Array(Set(moveOwners).union(beginByOwner.keys).union(closeOwners))
//         owners.sort()

//         var endByOwner: [Int: Decimal] = [:]
//         for oid in owners {
//             let d = deltas[oid] ?? OwnerDelta(stort: 0, onttrek: 0, winst: 0)
//             endByOwner[oid] = (beginByOwner[oid] ?? 0) + d.delta
//         }

//         let (openTotal, closeTotal) = equityPresentationTotals(
//             periodIndex: i, periods: allPeriods, chart: chart, cfg: cfg, maps: maps
//         )

//         var note: [Int: (Decimal, Decimal)] = [:]
//         for oid in owners {
//             let amt = alloc.usedAmounts[oid] ?? 0
//             let pct = alloc.usePosted
//                 ? ((alloc.niTotal == 0) ? 0 : (amt / alloc.niTotal))
//                 : (alloc.effectivePercents[oid] ?? 0)
//             note[oid] = (pct, amt)
//         }

//         let rows = PeriodRollforward(
//             owners: owners,
//             beginByOwner: beginByOwner,
//             deltas: deltas,
//             endByOwner: endByOwner,
//             niTotal: alloc.niTotal,
//             winstSource: alloc.source,
//             allocationNote: note,
//             openingTotal: openTotal,
//             closingTotal: closeTotal
//         )

//         // // Only print when within the requested view window (but always carry forward)
//         // if view == nil || view!.contains(i) {
//         //     printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)
//         // }

//         // adding hook
//         if view == nil || view!.contains(i) {
//             printPeriod(label: p.label, rows: rows, entities: entities, cfg: cfg)
//             afterEachPeriod?(p, owners, deltas, cfg)
//         }

//         beginByOwner = endByOwner
//     }
// }

// /// Async variant: uses `buildGlobalRollforwardConcurrent` to compute the
// /// global backsolve in parallel, then prints/handles only the requested view.
// public func runOwnerEquityRollforwardHistoryAsync(
//     title: String = "IB equity rollforward (owner split, backsolved)",
//     allPeriods: [EquityPeriod],
//     chart: CompiledChart,
//     entities: EntityStore,
//     view: ClosedRange<Int>?,                 // nil → print all
//     config cfg: EquityRollforwardConfig = .init(),
//     afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
// ) async throws {
//     guard !allPeriods.isEmpty else {
//         printHeader(title)
//         print("(no periods)")
//         return
//     }

//     // Header; anchor diagnostics are printed by `buildGlobalRollforwardConcurrent`
//     printHeader(title)

//     // Compute full global rollforward concurrently over all periods
//     let solved = try await buildGlobalRollforwardConcurrent(
//         history: allPeriods,
//         chart: chart,
//         entities: entities,
//         cfg: cfg
//     )

//     // Decide which indices to render
//     let indices: [Int]
//     if let viewRange = view {
//         let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
//         let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
//         indices = Array(clampedLower...clampedUpper)
//     } else {
//         indices = Array(allPeriods.indices)
//     }

//     // Print only the requested window, but use the globally solved rows
//     for i in indices {
//         let period = allPeriods[i]
//         let rows   = solved[i]

//         printPeriod(label: period.label, rows: rows, entities: entities, cfg: cfg)
//         afterEachPeriod?(period, rows.owners, rows.deltas, cfg)
//     }
// }

