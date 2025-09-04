import Foundation

public enum BusinessEntity: Sendable, Codable {
    case vof

    public func autoCloseTargets() -> AutoCloseTargets {
        var netIncomeCode: String
        var retainedEarningsCode: String

        switch self {
        case .vof:
            netIncomeCode        =  "WNerKapKap"
            retainedEarningsCode =  "BEivKapOndAow" // instead of level 4 BEivKapOnd
        }

        return AutoCloseTargets(
            netIncomeCode        :  netIncomeCode,
            retainedEarningsCode :  retainedEarningsCode
        )
    }

    /// Defaults you can tweak later per legal form.
    var periodOpeningRouting: PeriodOpeningRouting {
        switch self {
        case .vof:
            return .init(
                equityAnchorCode: "BEiv",
                equityOpeningCode: "BEivKapOndBeg",
                exceptionKeepLeafAnchors: ["BLim"] // cash & cash equivalents: keep at leaf
            )
        // // case .eenmanszaak: (add if you have it)
        // default:
        //     return .init(
        //         equityAnchorCode: "BEiv",
        //         equityOpeningCode: "BEivKapOndBeg",
        //         exceptionKeepLeafAnchors: ["BLim"]
        //     )
        }
    }
}
