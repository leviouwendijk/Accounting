import Foundation

public struct AnalyticsRoots: Sendable, Codable {
    public let netTurnoverCode: String
    public let costOfRevenueCode: String
    public let operatingExpensesCode: String
    public let depreciationExpensesCode: String
    public let financialResultCode: String

    public let liquidAssetsCode: String
    public let shortTermSecuritiesCode: String?
    public let receivablesCode: String?
    public let accruedCurrentAssetsCode: String?
    public let inventoryCode: String?
    public let workInProgressCode: String?

    public let currentLiabilitiesCode: String
    public let accruedCurrentLiabilitiesCode: String?

    public init(
        netTurnoverCode: String,
        costOfRevenueCode: String,
        operatingExpensesCode: String,
        depreciationExpensesCode: String,
        financialResultCode: String,
        liquidAssetsCode: String,
        shortTermSecuritiesCode: String? = nil,
        receivablesCode: String? = nil,
        accruedCurrentAssetsCode: String? = nil,
        inventoryCode: String? = nil,
        workInProgressCode: String? = nil,
        currentLiabilitiesCode: String,
        accruedCurrentLiabilitiesCode: String? = nil
    ) {
        self.netTurnoverCode = netTurnoverCode
        self.costOfRevenueCode = costOfRevenueCode
        self.operatingExpensesCode = operatingExpensesCode
        self.depreciationExpensesCode = depreciationExpensesCode
        self.financialResultCode = financialResultCode
        self.liquidAssetsCode = liquidAssetsCode
        self.shortTermSecuritiesCode = shortTermSecuritiesCode
        self.receivablesCode = receivablesCode
        self.accruedCurrentAssetsCode = accruedCurrentAssetsCode
        self.inventoryCode = inventoryCode
        self.workInProgressCode = workInProgressCode
        self.currentLiabilitiesCode = currentLiabilitiesCode
        self.accruedCurrentLiabilitiesCode = accruedCurrentLiabilitiesCode
    }
}
