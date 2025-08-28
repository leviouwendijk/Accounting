import Foundation

/// Aggregated section result (balance side only)
public struct BalanceAlphaSections: Sendable {
    public let totalsRaw: [RGSAssembleSection.Balance: Decimal]
    public let leafIds:  [RGSAssembleSection.Balance: [Int]]
    
    public init(
        totalsRaw: [RGSAssembleSection.Balance: Decimal],
        leafIds: [RGSAssembleSection.Balance: [Int]]
    ) {
        self.totalsRaw = totalsRaw
        self.leafIds = leafIds
    }

    public var assets: Decimal      { totalsRaw[.assets]     ?? 0 }
    public var equity: Decimal      { totalsRaw[.equity]     ?? 0 }
    public var liabilities: Decimal { totalsRaw[.liabilities] ?? 0 }
    public var diffRaw: Decimal { assets + equity + liabilities } // should be 0
}
