import Foundation

public struct RGSIndex: Sendable {
    public let byIdentifier: [String:Int]     // "BLimBanRba" -> node.id
    public let bySortKey: [String:Int]        // "A.F.0104000" -> node.id
    public let labelByGroupKey: [String:String] // groupKey (any level) -> labelShort
    public let byReference: [String:Int]    // in rare cases of referentienummer use
}
