import Foundation

public struct DrawingsGroup: Sendable {
    public let prefix: String   // RGS code prefix (e.g. "BEivKapProPmv")
    public let label: String    // display label
    public init(prefix: String, label: String) { self.prefix = prefix; self.label = label }
}

public struct EquityRollforwardConfig {
    public var entity: BusinessEntity = .vof
    public var fractionDigits: Int = 2
    public var contribCode: String = "BEivKapPrs"
    public var drawingCode: String = "BEivKapPro"
    public var equityTotalFallback: String? = "BEivKap"
    
    public init(
        entity: BusinessEntity = .vof,
        fractionDigits: Int = 2,
        contribCode: String = "BEivKapPrs",
        drawingCode: String = "BEivKapPro",
        equityTotalFallback: String? = "BEivKap"
    ) {
        self.entity = entity
        self.fractionDigits = fractionDigits
        self.contribCode = contribCode
        self.drawingCode = drawingCode
        self.equityTotalFallback = equityTotalFallback
    }

    public init() {}

    public var defaultDrawingGroups: [DrawingsGroup] {
        [
            .init(prefix: "BEivKapProPmv", label: "Privé-gebruik MVA"),
            .init(prefix: "BEivKapProPrg", label: "Privé-verbruik goederen"),
            .init(prefix: "BEivKapProPiz", label: "Privé-aandeel zakelijke lasten"),
            .init(prefix: "BEivKapProPpr", label: "Privé-premies"),
            // Common “shortcut” drawings outside Pro-branch; keep if you use them:
            .init(prefix: "BEivKapPoc",     label: "Privé-opname contant"),
            .init(prefix: "BEivKapPng",     label: "Privé (niet geboekt)"),
            .init(prefix: "BEivKapPbe",     label: "Privébelasting")
        ]
    }
}
