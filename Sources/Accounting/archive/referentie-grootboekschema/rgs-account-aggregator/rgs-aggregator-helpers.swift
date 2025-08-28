import Foundation

@inline(__always)
internal func _digits(_ s: String) -> Int { s.count }

@inline(__always)
internal func _familyKey(for n: Int, width: Int) -> FamilyKey {
    FamilyKey(value: (n / 1000) * 1000, width: width)
}

@inline(__always)
internal func _subclassKey(for n: Int, width: Int, family: FamilyKey) -> SubclassKey {
    let v: Int = (width == 5) ? ((n / 100) * 100) : ((n / 10) * 10)
    return SubclassKey(family: family, value: v)
}

@inline(__always)
internal func codeNumericLess(_ lhs: RGSAccount, _ rhs: RGSAccount) -> Bool {
    if let ln = Int(lhs.code), let rn = Int(rhs.code) { return ln < rn }
    return lhs.code < rhs.code
}
