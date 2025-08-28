import Foundation

public enum OmslagMode: Sendable, Codable { 
    case apply
    case ignore
}

public enum TargetLevel: Int, Sendable, Codable { 
    case L2 = 2
    case L3 = 3
    case L4 = 4
    case L5 = 5
}

public func chainToRoot(_ id: Int, parentById: [Int:Int]) -> [Int] {
    var out: [Int] = []
    var cur: Int? = id
    while let c = cur {
        out.append(c)
        cur = parentById[c]
    }
    return out
}
