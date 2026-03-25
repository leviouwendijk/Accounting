public func chainToRoot(_ id: Int, parentById: [Int:Int]) -> [Int] {
    var out: [Int] = []
    var cur: Int? = id
    while let c = cur {
        out.append(c)
        cur = parentById[c]
    }
    return out
}
