import Foundation

public struct PresentedBalanceTotals: Sendable {
    public let assets: Decimal
    public let equity: Decimal
    public let liabilities: Decimal
    
    public init(
        assets: Decimal,
        equity: Decimal,
        liabilities: Decimal
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
    }

    public var equityPlusLiabilities: Decimal { equity + liabilities }
}

