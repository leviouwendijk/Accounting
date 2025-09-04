import Foundation

extension RGSAssembler {

    /// Build pre-window opening seed with this priority:
    /// 1) L5 → L4's Beg child (if exists; disambiguate by trailing number; if ambiguous → keep at leaf)
    /// 2) If in Equity subtree → route to entity equityOpeningCode (or equity anchor group)
    /// 3) If under exception anchors (e.g. BLim) → keep at leaf
    /// 4) Default → keep at leaf (assume no special opening account)
    public static func openingBegSeed(
        from tbHist: [TrialBalanceRow],
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        routing: PeriodOpeningRouting
    ) -> [Int: Decimal] {

        // quick lookups
        let codeById  = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) })
        let labelById = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.labels.short.lowercased()) })
        let levelById = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.level) })

        // children cache
        var kidsByPid: [Int:[Int]] = [:]
        for n in chart.nodes { if let p = maps.parentById[n.id] { kidsByPid[p, default: []].append(n.id) } }

        @inline(__always) func isBegNode(_ id: Int) -> Bool {
            let c = codeById[id] ?? "", l = labelById[id] ?? ""
            return c.hasSuffix("Beg") || l.contains("beginbalans")
        }
        @inline(__always) func l4Parent(of id: Int) -> Int? {
            var cur: Int? = id
            while let c = cur {
                if levelById[c] == 4 { return c }
                cur = maps.parentById[c]
            }
            return nil
        }
        @inline(__always) func isDescendant(of anc: Int, id: Int) -> Bool {
            var cur: Int? = id
            while let c = cur {
                if c == anc { return true }
                cur = maps.parentById[c]
            }
            return false
        }

        // Precompute L4 → Beg children
        var begChildrenByL4: [Int:[Int]] = [:]
        for (pid, kids) in kidsByPid where levelById[pid] == 4 {
            let begs = kids.filter(isBegNode)
            if !begs.isEmpty { begChildrenByL4[pid] = begs }
        }

        // Anchors
        let equityAnchorId   = index.byIdentifier[routing.equityAnchorCode]
        let equityOpeningId  = routing.equityOpeningCode.flatMap { index.byIdentifier[$0] }
        let exceptionAnchorIds = routing.exceptionKeepLeafAnchors.compactMap { index.byIdentifier[$0] }

        // crude numeric disambiguation (“… 1/2/3”)
        @inline(__always) func trailingNumberHint(_ s: String) -> String? {
            let ds = s.split(whereSeparator: { !"0123456789".contains($0) })
            return ds.last.map { String($0) }
        }

        var out: [Int: Decimal] = [:]

        entries: for r in tbHist {
            guard let id = index.byIdentifier[r.accountCode] else { continue }
            guard maps.kindById[id] == .balance else { continue }   // only BS openings
            let amt = r.debit - r.credit
            if amt == 0 { continue }

            // Priority 0: if the row is itself a Beg leaf, keep it.
            if isBegNode(id) { out[id, default: 0] += amt; continue entries }

            // Priority 3 (exceptions): anchored branches must keep leaf (e.g., BLim)
            if exceptionAnchorIds.contains(where: { isDescendant(of: $0, id: id) }) {
                out[id, default: 0] += amt
                continue entries
            }

            // Priority 1: L5 → same-L4 Beg child
            let isL5 = (levelById[id] == 5)
            if isL5, let pL4 = l4Parent(of: id), let candidates = begChildrenByL4[pL4], !candidates.isEmpty {
                if candidates.count == 1 {
                    out[candidates[0], default: 0] += amt
                    continue entries
                } else {
                    // try trailing number match
                    let hint = trailingNumberHint(((labelById[id] ?? "") + " " + (codeById[id] ?? "")))
                    if let h = hint,
                       let chosen = candidates.first(where: {
                           (labelById[$0] ?? "").contains(h) || (codeById[$0] ?? "").contains(h)
                       }) {
                        out[chosen, default: 0] += amt
                        continue entries
                    }
                    // ambiguous → keep at leaf (no artificial group opening)
                    out[id, default: 0] += amt
                    continue entries
                }
            }

            // Priority 2: Equity subtree fallback to configured opening
            if let eqRoot = equityAnchorId, isDescendant(of: eqRoot, id: id) {
                if let eqBeg = equityOpeningId { out[eqBeg, default: 0] += amt }
                else { out[eqRoot, default: 0] += amt }
                continue entries
            }

            // Priority 4 (default): keep at leaf
            out[id, default: 0] += amt
        }

        return out
    }
}
