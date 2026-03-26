import Foundation

public extension CanonicalRoots {
    static let vof = CanonicalRoots(
        autoCloseTargets: .init(
            netIncomeCode: "WNerKapKap",
            retainedEarningsCode: "BEivKapOndAow"
        ),
        periodOpeningRouting: .init(
            equityAnchorCode: "BEiv",
            equityOpeningCode: "BEivKapOndBeg",
            exceptionKeepLeafAnchors: ["BLim"]
        ),
        capital: .init(
            profitShareCode: "BEivKapOndAow",
            contributionRootCode: "BEivKapPrs",
            drawingRootCode: "BEivKapPro",
            equityTotalFallbackCode: "BEivKap"
        ),
        analytics: .init(
            netTurnoverCode: "WOmz",
            costOfRevenueCode: "WKpr",
            operatingExpensesCode: "WBed",
            depreciationExpensesCode: "WAfs",
            financialResultCode: "WFbe",
            liquidAssetsCode: "BLim",
            shortTermSecuritiesCode: "BEff",
            receivablesCode: nil,
            accruedCurrentAssetsCode: nil,
            inventoryCode: "BVrd",
            workInProgressCode: nil,
            currentLiabilitiesCode: "BSch",
            accruedCurrentLiabilitiesCode: nil
        )
    )
}
