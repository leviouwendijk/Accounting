import Foundation

public struct EquityRollforwardConfig {
    public var entity: BusinessEntity = .vof
    public var fractionDigits: Int = 2
    public var contribCode: String = "BEivKapPrs"
    public var drawingCode: String = "BEivKapPro"
    public var equityTotalFallback: String? = "BEivKap"
    public init() {}
}
