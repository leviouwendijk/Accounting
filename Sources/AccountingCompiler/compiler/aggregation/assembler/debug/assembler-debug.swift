import Accounting
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
        verbose: Bool = true,
        dump: Bool = false
    ) throws -> StatementBundle {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)

        if dump {
            dumpParentCandidates(ch)
        }

        guard let index = ch.index else { throw NSError(domain: "RGSAssembler", code: 1, userInfo: [NSLocalizedDescriptionKey:"Missing index"]) }

        let maps = try RGSAssembler.makeMapsDebug(from: ch, verbose: verbose)
        // assertEdgesMatchKeys(maps)

        // seed
        let seed = RGSAssembler.seedLeafs(from: trialRows, using: index)
        try assertSeedSumsToZero(seed)

        compareRollupsAndPrint(seed: seed, maps: maps, index: index)

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

    // Debug: dump each node's keys + candidate parents
    public static func dumpParentCandidates(_ ch: CompiledChart) {
        guard let idx = ch.index else {
            fputs("dumpParentCandidates: no index\n", stderr)
            return
        }
        for n in ch.nodes {
            let id = n.id
            let code = n.codes.code
            let name = n.labels.short
            let key = n.xlsx?.cachedSortingKey ?? "<no-key>"
            let xParent = n.xlsx?.links.parentId.map { String($0) } ?? "<nil>"
            let pkey = (key.isEmpty ? nil : RGSNodeSortingCode(key: key).parentKeyString) ?? "<no-parentKey>"
            let resolvedByKey = pkey != "<no-parentKey>" ? (idx.bySortKey[pkey]?.description ?? "<missing>") : "<na>"
            let line = "NODE id=\(id) code=\(code) key='\(key)' name='\(name)' x.parent=\(xParent) parentKey='\(pkey)' indexLookup=\(resolvedByKey)\n"
            FileHandle.standardError.write(Data(line.utf8))
        }
    }

    // Compare two rollups and print top differences
    public static func compareRollupsAndPrint(seed: [Int: Decimal],
                                maps: RGSAssemblerResult,
                                index: RGSIndex,
                                top: Int = 30) {
        let totalsA = RGSAssembler.rollupAmounts(seed, parentById: maps.parentById) // parentId walk
        let totalsB = RGSAssembler.rollupBySortingKey(seed, idToKey: maps.sortKeyById, keyToId: maps.keyToId) // key walk

        // union ids
        let all = Set(totalsA.keys).union(Set(totalsB.keys)).union(Set(seed.keys))
        var diffs: [(id:Int, key:String, name:String, a:Decimal, b:Decimal, diff: Decimal)] = []
        for id in all {
            let a = totalsA[id] ?? 0
            let b = totalsB[id] ?? 0
            let d = (a - b).magnitude
            if d != 0 {
                let key = maps.sortKeyById[id] ?? "<no-key>"
                let name = maps.nameById[id] ?? "<no-name>"
                diffs.append((id, key, name, a, b, d))
            }
        }
        diffs.sort { $0.diff > $1.diff }
        FileHandle.standardError.write(Data(("R O L L U P  D I F F S  (top \(min(top, diffs.count)))\n").utf8))
        for t in diffs.prefix(top) {
            let s = "id=\(t.id) key='\(t.key)' name='\(t.name)' parentRoll=\(t.a) keyRoll=\(t.b) diff=\(t.diff)\n"
            FileHandle.standardError.write(Data(s.utf8))
            // then print parent chain for both parent-determined parent and key-determined parent
            if let pByParent = maps.parentById[t.id] {
                let pk = maps.sortKeyById[pByParent] ?? "<no-key>"
                FileHandle.standardError.write(Data(("  parentId(from x.links)=\(pByParent) key=\(pk)\n").utf8))
            }
            // find key parent
            if let k = maps.sortKeyById[t.id],
               let pkey = RGSNodeSortingCode(key: k).parentKeyString,
               let pid = maps.keyToId[pkey] {
                let pk = maps.sortKeyById[pid] ?? "<no-key>"
                FileHandle.standardError.write(Data(("  parentId(from key) =\(pid) key=\(pk)\n").utf8))
            }
        }
    }

    public func debugChain(forIdentifier idOrCode: String, ch: CompiledChart, maps: RGSAssemblerResult, index: RGSIndex) {
        // try code → id first
        var id: Int? = nil
        if let i = index.byIdentifier[idOrCode] { id = i }
        else if let i = Int(idOrCode) { id = i } // allow id input
        guard let start = id else {
            FileHandle.standardError.write(Data(("debugChain: no id for '\(idOrCode)'\n").utf8))
            return
        }
        var cur = start
        var out: [String] = []
        while true {
            let key = maps.sortKeyById[cur] ?? "<no-key>"
            let name = maps.nameById[cur] ?? "<no-name>"
            out.append("\(cur) [\(key)] \(name)")
            if let p = maps.parentById[cur] {
                cur = p
                continue
            }
            // fallback by key
            if let k = maps.sortKeyById[cur],
               let pk = RGSNodeSortingCode(key: k).parentKeyString,
               let pid = maps.keyToId[pk] {
                cur = pid
                continue
            }
            break
        }
        FileHandle.standardError.write(Data(("CHAIN for \(idOrCode):\n" + out.joined(separator: "  ->  ") + "\n").utf8))
    }


}
