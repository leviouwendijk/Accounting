import Foundation

public struct StatementBundle: Sendable {
    public let balance: [RGSPresentationLine]
    public let income:  [RGSPresentationLine]
    public let totalsById: [Int: Decimal]   // for debugging / future use
    
    public init(
        balance: [RGSPresentationLine],
        income: [RGSPresentationLine],
        totalsById: [Int: Decimal]   // for debugging / future use
    ) {
        self.balance = balance
        self.income = income
        self.totalsById = totalsById
    }
}
