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

            liquidAssetsCodes: ["BLim"],
            shortTermSecuritiesCodes: ["BEff"],

            receivablesCodes: ["BVor"],
            tradeReceivablesCodes: ["BVorDeb"],
            otherReceivablesCodes: ["BVorOvr"],
            accruedCurrentAssetsCodes: ["BVorOva"],

            inventoryCodes: ["BVrd"],
            workInProgressCodes: ["BPro"],

            currentLiabilitiesCodes: ["BSch"],
            tradeCreditorsCodes: ["BSchCre"],
            taxAndSocialChargesCodes: ["BSchBep"],
            otherCurrentLiabilitiesCodes: ["BSchOvs"],
            accruedCurrentLiabilitiesCodes: ["BSchOpa"],
            workInProgressLiabilityCodes: ["BSchOpp"]
        )
    )
}
