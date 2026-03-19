import Foundation

@inline(__always) public func rfDbg(_ s: @autoclosure () -> String) {
    print("[DEBUG] \(s())")
}
public func rfDumpOwnerMap(_ tag: String, map: [Int: Decimal], entities: EntityStore? = nil, digits: Int = 2) {
    let names: [Int?:String] = entities.map { ownerNameMap($0) } ?? [:]
    let total = map.values.reduce(0, +)
    print("[RF-DBG] \(tag): total=\(fmtDec(roundD(total, digits: digits), digits: digits))  owners=\(map.count)")
    for oid in map.keys.sorted() {
        let nm = names[Int?(oid)] ?? "owner#\(oid)"
        let amt = map[oid] ?? 0
        print("         - \(nm): \(fmtDec(roundD(amt, digits: digits), digits: digits))")
    }
}
