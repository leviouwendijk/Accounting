import Foundation

public extension RGSAssembler {

    /// AE variant: same rules as `openingBegSeed`, but preserves entity for non-equity.
    /// Historical equity stays in the equity opening target; pre-window NI may be ownership-split via `profitShareCode`.
    static func openingBegSeedAE(
        from tbHist: [TrialBalanceRow],
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult,
        routing: PeriodOpeningRouting,
        // pass the RGS code for "Aandeel in de overwinst" (your retainedEarningsCode for VOF)
        profitShareCode: String?,
        // optional: split ownership if you provide non-empty slices (percents must sum to ~1)
        ownershipSlices: [OwnershipSlice] = [],
        // when you can’t provide entity ids on rows, this closure can map row→entityId (often nil)
        entityIdOnRow: (TrialBalanceRow) -> Int? = { _ in nil }
    ) -> [AccEntKey: Decimal] {

        // Quick lookups
        let nodes = chart.nodes
        let codeById  = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.codes.code) })
        let labelById = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.labels.short.lowercased()) })
        let levelById = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0.level) })

        // Child cache
        var kidsByPid: [Int:[Int]] = [:]
        for n in nodes { if let p = maps.parentById[n.id] { kidsByPid[p, default: []].append(n.id) } }

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

        // Anchors/ids
        let equityAnchorId   = index.byIdentifier[routing.equityAnchorCode]
        let equityOpeningId  = routing.equityOpeningCode.flatMap { index.byIdentifier[$0] }
        let exceptionAnchorIds = routing.exceptionKeepLeafAnchors.compactMap { index.byIdentifier[$0] }
        let profitShareId    = profitShareCode.flatMap { index.byIdentifier[$0] }

        // crude numeric disambiguation (“… 1/2/3”)
        @inline(__always) func trailingNumberHint(_ s: String) -> String? {
            let ds = s.split(whereSeparator: { !"0123456789".contains($0) })
            return ds.last.map { String($0) }
        }

        var out: [AccEntKey: Decimal] = [:]
        @inline(__always) func push(_ accId: Int, _ entId: Int?, _ v: Decimal) {
            guard v != 0 else { return }
            out[AccEntKey(accId, entId), default: 0] += v
        }

        entries: for r in tbHist {
            guard let id = index.byIdentifier[r.accountCode] else { continue }
            guard maps.kindById[id] == .balance else { continue }   // only BS openings
            let amt = r.debit - r.credit
            if amt == 0 { continue }
            let eid = entityIdOnRow(r)

            // Priority 0: if row is itself a Beg leaf, keep (preserve eid).
            if isBegNode(id) { push(id, eid, amt); continue entries }

            // Priority 3 (exceptions): anchored branches keep leaf
            if exceptionAnchorIds.contains(where: { isDescendant(of: $0, id: id) }) {
                push(id, eid, amt); continue entries
            }

            // Priority 1: L5 → same-L4 Beg child
            if levelById[id] == 5, let pL4 = l4Parent(of: id),
               let cands = begChildrenByL4[pL4], !cands.isEmpty {
                if cands.count == 1 {
                    push(cands[0], eid, amt); continue entries
                } else {
                    let hint = trailingNumberHint(((labelById[id] ?? "") + " " + (codeById[id] ?? "")))
                    if let h = hint,
                       let chosen = cands.first(where: {
                           (labelById[$0] ?? "").contains(h) || (codeById[$0] ?? "").contains(h)
                       }) {
                        push(chosen, eid, amt); continue entries
                    }
                    // ambiguous → keep at leaf
                    push(id, eid, amt); continue entries
                }
            }

            // // Priority 2: Equity subtree fallback
            // if let eqRoot = equityAnchorId, isDescendant(of: eqRoot, id: id) {
            //     // Special-case: profit-share → split by ownership if provided
            //     if let psId = profitShareId, !ownershipSlices.isEmpty {
            //         for s in ownershipSlices where s.percent != 0 {
            //             push(psId, s.entityId, amt * s.percent)
            //         }
            //     } else if let eqBeg = equityOpeningId {
            //         push(eqBeg, eid, amt)
            //     } else {
            //         push(eqRoot, eid, amt)
            //     }
            //     continue entries
            // }

            // Priority 2: Equity subtree fallback
            if let eqRoot = equityAnchorId, isDescendant(of: eqRoot, id: id) {
                if let eqBeg = equityOpeningId {
                    push(eqBeg, eid, amt)
                } else {
                    push(eqRoot, eid, amt)
                }
                continue entries
            }

            // Priority 4 (default): keep at leaf
            push(id, eid, amt)
        }

        // return out

        // === PRE-WINDOW NI INJECTION (AE) ===============================
        // Mirror plain opening semantics:
        // - historical balance-sheet equity stays in equity opening
        // - historical net income is injected separately
        // - only that NI injection may be ownership-split
        if let eqTarget = (equityOpeningId ?? equityAnchorId) {
            var preNI: Decimal = 0
            for r in tbHist {
                guard let id = index.byIdentifier[r.accountCode] else { continue }
                if maps.kindById[id] == .income {
                    preNI += (r.debit - r.credit)
                }
            }

            if preNI != 0 {
                if !ownershipSlices.isEmpty {
                    let target = profitShareId ?? eqTarget
                    for s in ownershipSlices where s.percent != 0 {
                        push(target, s.entityId, preNI * s.percent)
                    }
                } else {
                    push(eqTarget, nil, preNI)
                }
            }
        }
        // ===============================================================
        return out
    }
}
