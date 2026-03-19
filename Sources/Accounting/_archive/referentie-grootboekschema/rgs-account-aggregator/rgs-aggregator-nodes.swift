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

    public var title: String? {
        if let l2 = headersL2.first?.label { return l2 }
        // optional fallback: first subclass L3 header
        if let anySub = subclasses.values.sorted(by: { $0.key.value < $1.key.value }).first,
           let l3 = anySub.headersL3.first?.label {
            return l3
        }
        return nil
    }
}

public struct SubclassNode: Sendable {
    public let key: SubclassKey
    public var headersL3: [RGSAccount]      // level 3 accounts at this subclass
    public var leavesL4: [RGSAccount]       // level 4 accounts under this subclass
    public var title: String? {
        if let l3 = headersL3.first?.label { return l3 }
        if let l4 = leavesL4.first?.label { return l4 }
        return nil
    }
}
