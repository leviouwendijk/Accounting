import Foundation

public struct RGSAccountAggregator: Sendable {
    public let families: [FamilyKey: FamilyNode]

    public init(accounts: [RGSAccount]) {
        var fams: [FamilyKey: FamilyNode] = [:]

        @inline(__always)
        func sortFamilyNode(_ f: FamilyNode) -> FamilyNode {
            var f2 = f
            f2.headersL2.sort(by: codeNumericLess)
            f2.subclasses = Dictionary(uniqueKeysWithValues:
                f2.subclasses.map { (k, s) -> (SubclassKey, SubclassNode) in
                    var s2 = s
                    s2.headersL3.sort(by: codeNumericLess)
                    s2.leavesL4.sort(by: codeNumericLess)
                    return (k, s2)
                }
            )
            return f2
        }

        for a in accounts {
            guard let n = Int(a.code) else { continue }
            let w = _digits(a.code)
            guard w == 4 || w == 5 else { continue }

            let fKey = _familyKey(for: n, width: w)
            var fNode = fams[fKey] ?? FamilyNode(key: fKey, headersL2: [], subclasses: [:])

            switch a.level {
            case 2:
                fNode.headersL2.append(a)
            case 3:
                let sKey = _subclassKey(for: n, width: w, family: fKey)
                var sNode = fNode.subclasses[sKey] ?? SubclassNode(key: sKey, headersL3: [], leavesL4: [])
                sNode.headersL3.append(a)
                fNode.subclasses[sKey] = sNode
            default:
                let sKey = _subclassKey(for: n, width: w, family: fKey)
                var sNode = fNode.subclasses[sKey] ?? SubclassNode(key: sKey, headersL3: [], leavesL4: [])
                sNode.leavesL4.append(a)
                fNode.subclasses[sKey] = sNode
            }

            fams[fKey] = fNode
        }

        self.families = Dictionary(uniqueKeysWithValues: fams.map { (k, v) in (k, sortFamilyNode(v)) })
    }

    public func sortedFamilies() -> [FamilyNode] {
        families.values.sorted { $0.key.value < $1.key.value }
    }

    public func sortedSubclasses(in family: FamilyKey) -> [SubclassNode] {
        guard let f = families[family] else { return [] }
        return f.subclasses.values.sorted { $0.key.value < $1.key.value }
    }

    public func accounts(in family: FamilyKey) -> [RGSAccount] {
        guard let f = families[family] else { return [] }
        var result = f.headersL2
        for sub in f.subclasses.values {
            result.append(contentsOf: sub.headersL3)
            result.append(contentsOf: sub.leavesL4)
        }
        return result.sorted(by: codeNumericLess)
    }

    public func accounts(in subclass: SubclassKey) -> [RGSAccount] {
        guard let f = families[subclass.family], let s = f.subclasses[subclass] else { return [] }
        return (s.headersL3 + s.leavesL4).sorted(by: codeNumericLess)
    }

    public var allLeaves: [RGSAccount] {
        families.values.flatMap { $0.subclasses.values }.flatMap { $0.leavesL4 }.sorted(by: codeNumericLess)
    }

    public func groupL4ByParent(in sub: SubclassNode) -> (pairs: [(parent: RGSAccount, children: [RGSAccount])], orphans: [RGSAccount]) {
        // Build sorted L3 list (by numeric code)
        func num(_ a: RGSAccount) -> Int { Int(a.code) ?? Int.max }
        let l3Sorted = sub.headersL3.sorted { num($0) < num($1) }

        // Fast exit: no L3 headers → all leaves are orphans
        guard !l3Sorted.isEmpty else {
            let orphans = sub.leavesL4.sorted { num($0) < num($1) }
            return (pairs: [], orphans: orphans)
        }

        // Map parent code -> accumulated children
        var children: [String: [RGSAccount]] = Dictionary(uniqueKeysWithValues: l3Sorted.map { ($0.code, []) })

        // Subclass numeric span (helps keep things clean, but not strictly required)
        // We assume all codes in this SubclassNode share the same width (4 or 5).
        // Use the key value as the subclass start, infer width from string lengths present.
        let subclassStart = sub.key.value
        let width = sub.headersL3.first?.code.count ?? sub.leavesL4.first?.code.count ?? 5
        let subclassEnd = subclassStart + (width == 5 ? 99 : 9)

        // For each leaf, find the right L3 parent: max(L3.code) where L3.code <= leaf.code
        for leaf in sub.leavesL4 {
            guard let ln = Int(leaf.code) else { continue }
            // (Optional) keep leaves within the subclass numeric window
            guard ln >= subclassStart, ln <= subclassEnd else { continue }

            // linear scan is fine (handful per subclass); switch to binary search if you want
            var picked: RGSAccount? = nil
            for p in l3Sorted {
                if let pn = Int(p.code), pn <= ln {
                    picked = p
                } else {
                    break
                }
            }

            if let parent = picked {
                children[parent.code, default: []].append(leaf)
            } else {
                // no L3 <= leaf → orphan
                children["__ORPHAN__", default: []].append(leaf)
            }
        }

        func numLess(_ a: RGSAccount, _ b: RGSAccount) -> Bool {
            if let x = Int(a.code), let y = Int(b.code) { return x < y }
            return a.code < b.code
        }

        // Build ordered (parent, children) pairs
        let pairs: [(RGSAccount, [RGSAccount])] = l3Sorted.map { p in
            let kids = (children[p.code] ?? []).sorted(by: numLess)
            return (p, kids)
        }

        // Orphans that didn’t find a parent L3
        let orphans = (children["__ORPHAN__"] ?? []).sorted(by: numLess)
        return (pairs: pairs, orphans: orphans)
    }

}
