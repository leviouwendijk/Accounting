import Foundation

public struct FamilyKey: Hashable, Sendable, CustomStringConvertible {
    public let value: Int          // canonical integer bucket (e.g. 10000 or 1000)
    public let width: Int          // code width (4 or 5)

    public var description: String {
        String(format: "%0\(width)d", value)
    }
}

public struct SubclassKey: Hashable, Sendable, CustomStringConvertible {
    public let family: FamilyKey
    public let value: Int          // e.g. 10100 (5d) or 1110 (4d)
    public var description: String {
        String(format: "%0\(family.width)d", value)
    }
}

public struct FamilyNode: Sendable {
    public let key: FamilyKey
    public var headersL2: [RGSAccount]      // level 2 accounts at this family
    public var subclasses: [SubclassKey: SubclassNode]
}

public struct SubclassNode: Sendable {
    public let key: SubclassKey
    public var headersL3: [RGSAccount]      // level 3 accounts at this subclass
    public var leavesL4: [RGSAccount]       // level 4 accounts under this subclass
}

public struct RGSAccountAggregator: Sendable {
    public let families: [FamilyKey: FamilyNode]

    public init(accounts: [RGSAccount]) {
        var fams: [FamilyKey: FamilyNode] = [:]

        @inline(__always)
        func digits(_ s: String) -> Int { s.count } // already validated numeric upstream

        @inline(__always)
        func familyKey(for n: Int, width: Int) -> FamilyKey {
            // Family (L2) bucket:
            // 5d → 10k bucket (xx000)  == (n / 1000) * 1000
            // 4d → 1k  bucket (x000)   == (n / 1000) * 1000
            let start = (n / 1000) * 1000
            return FamilyKey(value: start, width: width)
        }

        @inline(__always)
        func subclassKey(for n: Int, width: Int, family: FamilyKey) -> SubclassKey {
            // Subclass (L3) bucket:
            // 5d → hundreds (xx000, xx100, xx200, …): (n / 100) * 100
            // 4d → tens     (x000, x010, x020, …):    (n / 10)  * 10
            let v: Int = (width == 5) ? ((n / 100) * 100) : ((n / 10) * 10)
            return SubclassKey(family: family, value: v)
        }

        @inline(__always)
        func sortFamilyNode(_ f: FamilyNode) -> FamilyNode {
            var f2 = f
            f2.headersL2.sort(by: codeNumericLess)
            // map to a *new* dictionary so we don't capture self
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
            // Validate numeric once
            guard let n = Int(a.code) else { continue }
            let w = digits(a.code)

            // Only support 4/5-digit codes (your dataset); skip others deterministically
            guard w == 4 || w == 5 else { continue }

            let level =  a.level

            let fKey = familyKey(for: n, width: w)
            var fNode = fams[fKey] ?? FamilyNode(key: fKey, headersL2: [], subclasses: [:])

            if level == 2 {
                fNode.headersL2.append(a)
            } else {
                let sKey = subclassKey(for: n, width: w, family: fKey)
                var sNode = fNode.subclasses[sKey] ?? SubclassNode(key: sKey, headersL3: [], leavesL4: [])

                if level == 3 {
                    sNode.headersL3.append(a)
                } else {
                    // level 4 by definition
                    sNode.leavesL4.append(a)
                }
                fNode.subclasses[sKey] = sNode
            }

            fams[fKey] = fNode
        }

        let sortedFamilies: [FamilyKey: FamilyNode] = Dictionary(uniqueKeysWithValues: fams.map { (k, v) in (k, sortFamilyNode(v)) })

        self.families = sortedFamilies
    }

    public func sortedFamilies() -> [FamilyNode] {
        families.values.sorted { $0.key.value < $1.key.value }
    }

    public func sortedSubclasses(in family: FamilyKey) -> [SubclassNode] {
        guard let f = families[family] else { return [] }
        return f.subclasses.values.sorted { $0.key.value < $1.key.value }
    }
    
    public func printTree(maxLines: Int = 12) {
        for fam in sortedFamilies() {
            print("# Family \(fam.key)")
            if !fam.headersL2.isEmpty {
                for a in fam.headersL2.prefix(maxLines) {
                    print("  L2  \(a.code)  \(a.label)")
                }
                if fam.headersL2.count > maxLines {
                    print("  … +\(fam.headersL2.count - maxLines) more L2")
                }
            }
            let subclasses = fam.subclasses.values.sorted { $0.key.value < $1.key.value }
            for sub in subclasses {
                print("  ## Subclass \(sub.key)")
                for a in sub.headersL3.prefix(maxLines) {
                    print("    L3  \(a.code)  \(a.label)")
                }
                if sub.headersL3.count > maxLines {
                    print("    … +\(sub.headersL3.count - maxLines) more L3")
                }
                for a in sub.leavesL4.prefix(maxLines) {
                    print("    L4  \(a.code)  \(a.label)")
                }
                if sub.leavesL4.count > maxLines {
                    print("    … +\(sub.leavesL4.count - maxLines) more L4")
                }
            }
        }
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

    /// All L3 + L4 under one subclass
    public func accounts(in subclass: SubclassKey) -> [RGSAccount] {
        guard let f = families[subclass.family],
              let s = f.subclasses[subclass] else { return [] }
        return (s.headersL3 + s.leavesL4).sorted(by: codeNumericLess)
    }

    /// All leaves (L4) across everything — useful for bottom-up aggregation
    public var allLeaves: [RGSAccount] {
        families.values
            .flatMap { $0.subclasses.values }
            .flatMap { $0.leavesL4 }
            .sorted(by: codeNumericLess)
    }
}

@inline(__always)
private func codeNumericLess(_ lhs: RGSAccount, _ rhs: RGSAccount) -> Bool {
    if let ln = Int(lhs.code), let rn = Int(rhs.code) { return ln < rn }
    return lhs.code < rhs.code
}

public extension FamilyNode {
    func debugPrint(maxLines: Int = 10) {
        print("# Family \(key)")
        for h in headersL2.prefix(maxLines) {
            print("  L2  \(h.code) \(h.label)")
        }
        for s in subclasses.values.sorted(by: { $0.key.value < $1.key.value }) {
            print("  ## Subclass \(s.key)")
            for h in s.headersL3.prefix(maxLines) { print("    L3  \(h.code) \(h.label)") }
            for l in s.leavesL4.prefix(maxLines) { print("    L4  \(l.code) \(l.label)") }
        }
    }
}
