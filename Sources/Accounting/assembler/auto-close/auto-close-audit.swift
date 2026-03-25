import Foundation

public struct AutoCloseAudit: Sendable {
    public let ni: Decimal
    public let niNode: (code: String, id: Int)
    public let equityNode: (code: String, id: Int)
    public let adjustedForManual: Decimal
    public let suppressed: Bool
    
    public init(
        ni: Decimal,
        niNode: (code: String, id: Int),
        equityNode: (code: String, id: Int),
        adjustedForManual: Decimal,
        suppressed: Bool
    ) {
        self.ni = ni
        self.niNode = niNode
        self.equityNode = equityNode
        self.adjustedForManual = adjustedForManual
        self.suppressed = suppressed
    }
}
