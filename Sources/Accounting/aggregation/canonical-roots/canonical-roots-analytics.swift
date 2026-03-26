import Foundation

public struct AnalyticsRoots: Sendable, Codable {
    public let netTurnoverCode: String
    public let costOfRevenueCode: String
    public let operatingExpensesCode: String
    public let depreciationExpensesCode: String
    public let financialResultCode: String

    public let liquidAssetsCodes: [String]
    public let shortTermSecuritiesCodes: [String]

    /// Broad fallback only. Prefer the more specific buckets below when present.
    public let receivablesCodes: [String]
    public let tradeReceivablesCodes: [String]
    public let otherReceivablesCodes: [String]
    public let accruedCurrentAssetsCodes: [String]

    public let inventoryCodes: [String]
    public let workInProgressCodes: [String]

    /// Broad fallback only. Prefer the more specific buckets below when present.
    public let currentLiabilitiesCodes: [String]
    public let tradeCreditorsCodes: [String]
    public let taxAndSocialChargesCodes: [String]
    public let otherCurrentLiabilitiesCodes: [String]
    public let accruedCurrentLiabilitiesCodes: [String]
    public let workInProgressLiabilityCodes: [String]

    public init(
        netTurnoverCode: String,
        costOfRevenueCode: String,
        operatingExpensesCode: String,
        depreciationExpensesCode: String,
        financialResultCode: String,
        liquidAssetsCodes: [String] = [],
        shortTermSecuritiesCodes: [String] = [],
        receivablesCodes: [String] = [],
        tradeReceivablesCodes: [String] = [],
        otherReceivablesCodes: [String] = [],
        accruedCurrentAssetsCodes: [String] = [],
        inventoryCodes: [String] = [],
        workInProgressCodes: [String] = [],
        currentLiabilitiesCodes: [String] = [],
        tradeCreditorsCodes: [String] = [],
        taxAndSocialChargesCodes: [String] = [],
        otherCurrentLiabilitiesCodes: [String] = [],
        accruedCurrentLiabilitiesCodes: [String] = [],
        workInProgressLiabilityCodes: [String] = []
    ) {
        self.netTurnoverCode = netTurnoverCode
        self.costOfRevenueCode = costOfRevenueCode
        self.operatingExpensesCode = operatingExpensesCode
        self.depreciationExpensesCode = depreciationExpensesCode
        self.financialResultCode = financialResultCode

        self.liquidAssetsCodes = liquidAssetsCodes
        self.shortTermSecuritiesCodes = shortTermSecuritiesCodes

        self.receivablesCodes = receivablesCodes
        self.tradeReceivablesCodes = tradeReceivablesCodes
        self.otherReceivablesCodes = otherReceivablesCodes
        self.accruedCurrentAssetsCodes = accruedCurrentAssetsCodes

        self.inventoryCodes = inventoryCodes
        self.workInProgressCodes = workInProgressCodes

        self.currentLiabilitiesCodes = currentLiabilitiesCodes
        self.tradeCreditorsCodes = tradeCreditorsCodes
        self.taxAndSocialChargesCodes = taxAndSocialChargesCodes
        self.otherCurrentLiabilitiesCodes = otherCurrentLiabilitiesCodes
        self.accruedCurrentLiabilitiesCodes = accruedCurrentLiabilitiesCodes
        self.workInProgressLiabilityCodes = workInProgressLiabilityCodes
    }
}
