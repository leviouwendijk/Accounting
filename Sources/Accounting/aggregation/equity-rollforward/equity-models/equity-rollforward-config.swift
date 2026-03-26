import Foundation

public struct DrawingsGroup: Sendable {
    public let prefix: String
    public let label: String

    public init(
        prefix: String,
        label: String
    ) {
        self.prefix = prefix
        self.label = label
    }
}

public struct EquityRollforwardConfig: Sendable {
    public var entity: BusinessEntity
    public var fractionDigits: Int
    public var contribCode: String
    public var drawingCode: String
    public var equityTotalFallback: String?

    public init(
        entity: BusinessEntity = .vof,
        fractionDigits: Int = 2,
        contribCode: String? = nil,
        drawingCode: String? = nil,
        equityTotalFallback: String? = nil
    ) {
        let roots = entity.capitalRoots

        self.entity = entity
        self.fractionDigits = fractionDigits
        self.contribCode = contribCode ?? roots.contributionRootCode
        self.drawingCode = drawingCode ?? roots.drawingRootCode
        self.equityTotalFallback = equityTotalFallback ?? roots.equityTotalFallbackCode
    }

    public init() {
        self.init(entity: .vof)
    }

    public var defaultDrawingGroups: [DrawingsGroup] {
        [
            .init(prefix: "BEivKapProPok", label: "Privé-opname kapitaal"),
            .init(prefix: "BEivKapProPmv", label: "Privé-gebruik MVA"),
            .init(prefix: "BEivKapProPrg", label: "Privé-verbruik goederen"),
            .init(prefix: "BEivKapProPiz", label: "Privé-aandeel zakelijke lasten"),
            .init(prefix: "BEivKapProPpr", label: "Privé-premies"),
            .init(prefix: "BEivKapProPri", label: "Privé-belastingen"),
            .init(prefix: "BEivKapProPer", label: "Privé-aflossingen en rente"),
            .init(prefix: "BEivKapProPrk", label: "Privé-aftrekbare kosten"),
            .init(prefix: "BEivKapProFor", label: "FOR (dotatie)"),
            .init(prefix: "BEivKapProOvp", label: "Overige privé-opnamen"),
            .init(prefix: "BEivKapPoc", label: "Privé-onttrekking contanten"),
            .init(prefix: "BEivKapPng", label: "Privé-onttrekking in natura en goederen"),
            .init(prefix: "BEivKapPbe", label: "Privé-belastingen"),
            .init(prefix: "BEivKapPpr", label: "Privé-premies")
        ]
    }
}

// public struct DrawingsGroup: Sendable {
//     public let prefix: String   // RGS code prefix (e.g. "BEivKapProPmv")
//     public let label: String    // display label
//     public init(prefix: String, label: String) { self.prefix = prefix; self.label = label }
// }

// public struct EquityRollforwardConfig: Sendable {
//     public var entity: BusinessEntity = .vof
//     public var fractionDigits: Int = 2
//     public var contribCode: String = "BEivKapPrs"
//     public var drawingCode: String = "BEivKapPro"
//     public var equityTotalFallback: String? = "BEivKap"
    
//     public init(
//         entity: BusinessEntity = .vof,
//         fractionDigits: Int = 2,
//         contribCode: String = "BEivKapPrs",
//         drawingCode: String = "BEivKapPro",
//         equityTotalFallback: String? = "BEivKap"
//     ) {
//         self.entity = entity
//         self.fractionDigits = fractionDigits
//         self.contribCode = contribCode
//         self.drawingCode = drawingCode
//         self.equityTotalFallback = equityTotalFallback
//     }

//     public init() {}

//     public var defaultDrawingGroups: [DrawingsGroup] {
//         [
//             .init(prefix: "BEivKapProPok", label: "Privé-opname kapitaal"),
//             .init(prefix: "BEivKapProPmv", label: "Privé-gebruik MVA"),
//             .init(prefix: "BEivKapProPrg", label: "Privé-verbruik goederen"),
//             .init(prefix: "BEivKapProPiz", label: "Privé-aandeel zakelijke lasten"),
//             .init(prefix: "BEivKapProPpr", label: "Privé-premies"),
//             .init(prefix: "BEivKapProPri", label: "Privé-belastingen"),
//             .init(prefix: "BEivKapProPer", label: "Privé-aflossingen en rente"),
//             .init(prefix: "BEivKapProPrk", label: "Privé-aftrekbare kosten"),
//             .init(prefix: "BEivKapProFor", label: "FOR (dotatie)"),
//             .init(prefix: "BEivKapProOvp", label: "Overige privé-opnamen"),
//              // Common “shortcut” drawings outside Pro-branch:
//             .init(prefix: "BEivKapPoc",     label: "Privé-onttrekking contanten"),
//             .init(prefix: "BEivKapPng",     label: "Privé-onttrekking in natura en goederen"),
//             .init(prefix: "BEivKapPbe",     label: "Privé-belastingen"),
//             .init(prefix: "BEivKapPpr",     label: "Privé-premies")
//         ]
//     }
// }
