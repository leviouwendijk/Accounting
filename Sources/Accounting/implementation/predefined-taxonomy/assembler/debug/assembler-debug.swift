// ---------- DEBUG helpers (drop-in) ----------

import Foundation


extension RGSAssembler {
    // debug variant of makeMaps — more robust key normalization and logging
    public static func makeMapsDebug(from chart: CompiledChart, verbose: Bool = true) throws -> RGSAssemblerResult {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let idx = ch.index else { fatalError("index missing") }

        var kindById: [Int: StatementKind] = [:]
        var sortKeyById: [Int: String] = [:]
        var directionById: [Int: Direction] = [:]
        var parentById: [Int: Int] = [:]
        var keyToId: [String: Int] = [:]
        var nameById: [Int: String] = [:]

        // normalize the index's keyToId into trimmed canonical keys
        for (k, id) in idx.bySortKey {
            let nk = k.trimmingCharacters(in: .whitespacesAndNewlines)
            if keyToId[nk] != nil {
                // duplicate detected; log if verbose
                if verbose {
                    let msg = "RGSIndex: duplicate sort-key (index) '\(nk)' -> ignoring duplicate for id \(id)\n"
                    FileHandle.standardError.write(Data(msg.utf8))
                }
                // keep first inserted
            } else {
                keyToId[nk] = id
            }
        }

        // build maps; ensure sort keys used here are normalized like index keys
        var missingParentLookups: [(id: Int, key: String, parentKey: String)] = []
        for n in ch.nodes {
            if let x = n.xlsx {
                let rawKey = x.cachedSortingKey
                let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
                sortKeyById[n.id] = key
                if let pid = x.links.parentId {
                    parentById[n.id] = pid
                } else {
                    // try parent prefix lookup using normalized key
                    if let pkey = RGSNodeSortingCode(key: key).parentKeyString {
                        let pk = pkey.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let pid = keyToId[pk] {
                            parentById[n.id] = pid
                        } else {
                            missingParentLookups.append((n.id, key, pk))
                        }
                    }
                }
                directionById[n.id] = n.direction
                nameById[n.id] = n.labels.short
                if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
                else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }
            } else {
                directionById[n.id] = n.direction
                nameById[n.id] = n.labels.short
            }
        }

        if verbose {
            let totalNodes = ch.nodes.count
            let mappedParents = parentById.count
            let msgs = """
            RGS makeMapsDebug: nodes=\(totalNodes), parentLinksResolved=\(mappedParents)
            Missing parent lookups: \(missingParentLookups.count)
            """
            FileHandle.standardError.write(Data((msgs + "\n").utf8))
            // print some sample missing parent key lookups
            for m in missingParentLookups.prefix(20) {
                let s = "  missing: id=\(m.id) key='\(m.key)' parentKeyCandidate='\(m.parentKey)'\n"
                FileHandle.standardError.write(Data(s.utf8))
            }
            if !missingParentLookups.isEmpty {
                FileHandle.standardError.write(Data("Tip: run RGSIndex.build(..., strict:true) to detect duplicate/missing keys early.\n".utf8))
            }
        }

        return .init(
            totalsById: [:],
            kindById: kindById,
            sortKeyById: sortKeyById,
            directionById: directionById,
            parentById: parentById,
            keyToId: keyToId,
            nameById: nameById
        )
    }

    // small helper to run both rollups and print diagnostics
    public static func assembleWithDiagnostics(
        chart: CompiledChart,
        trialRows: [TrialBalanceRow],
        cut: AssembleCut,
        omslag: OmslagMode,
        verbose: Bool = true
    ) throws -> StatementBundle {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw NSError(domain: "RGSAssembler", code: 1, userInfo: [NSLocalizedDescriptionKey:"Missing index"]) }

        // let maps = try RGSAssembler.makeMaps(from: ch)
        let maps = try RGSAssembler.makeMapsDebug(from: ch, verbose: verbose)

        // seed
        let seed = RGSAssembler.seedLeafs(from: trialRows, using: index)

        // rollup A: by explicit parent links
        let totalsA = RGSAssembler.rollupAmounts(seed, parentById: maps.parentById)
        // rollup B: by deterministic sorting-key prefix climb
        let totalsB = RGSAssembler.rollupBySortingKey(seed, idToKey: maps.sortKeyById, keyToId: maps.keyToId)

        // compare
        compareRollups(seed: seed, parentTotals: totalsA, keyTotals: totalsB, maps: maps, verbose: verbose)

        // choose totalsB as authoritative if parentById seemed sparse
        // (Don't change behavior yet — keep both available; choose one consistently.)
        let chosenTotals = totalsB

        // forced inclusions
        let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = cut.includeIntermediates
            ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) })
            : forcedIds

        let labels = index.labelByGroupKey
        let bs = linesFor(.balance, roll: maps, totals: chosenTotals, labels: labels,
                          cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)
        let is_ = linesFor(.income, roll: maps, totals: chosenTotals, labels: labels,
                           cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)

        return StatementBundle(balance: bs, income: is_, totalsById: chosenTotals)
    }

    // helper: pretty print differences between two rollups
    @inline(__always)
    public static func compareRollups(
        seed: [Int: Decimal],
        parentTotals: [Int: Decimal],
        keyTotals: [Int: Decimal],
        maps: RGSAssemblerResult,
        topN: Int = 20,
        verbose: Bool = true
    ) {
        // compute absolute difference per id (only where either non-zero)
        var diffs: [(id: Int, key: String, name: String, a: Decimal, b: Decimal, diff: Decimal)] = []
        let allIds = Set(parentTotals.keys).union(Set(keyTotals.keys)).union(Set(seed.keys))
        for id in allIds {
            let a = parentTotals[id] ?? 0
            let b = keyTotals[id] ?? 0
            let d = (a - b).magnitude
            if d != 0 {
                let key = maps.sortKeyById[id] ?? ""
                let name = maps.nameById[id] ?? "—"
                diffs.append((id, key, name, a, b, d))
            }
        }
        diffs.sort { $0.diff > $1.diff }
        if !verbose { return }
        if diffs.isEmpty {
            FileHandle.standardError.write(Data("RGS: rollups MATCH (no diffs)\n".utf8))
            return
        }
        FileHandle.standardError.write(Data("RGS: rollup DIFFS (top \(min(topN, diffs.count))):\n".utf8))
        for t in diffs.prefix(topN) {
            let s = "  id=\(t.id) key='\(t.key)' name='\(t.name)' parentRoll=\(t.a) keyRoll=\(t.b) diff=\(t.diff)\n"
            FileHandle.standardError.write(Data(s.utf8))
        }
    }
}
