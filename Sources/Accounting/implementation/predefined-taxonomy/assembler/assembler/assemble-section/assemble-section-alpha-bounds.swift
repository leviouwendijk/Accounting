import Foundation

public struct AlphaBounds: Sendable, Codable, Equatable {
    /// Assets: [assetsStart, equityStart)
    /// Equity:  [equityStart, liabilitiesStart)
    /// Liab:    [liabilitiesStart, pAndLStart)
    /// P&L:     [pAndLStart, "Z̄")  (not used here, but good to keep)
    public let assetsStart: String       // "A"
    public let equityStart: String       // "J"
    public let liabilitiesStart: String  // "K"
    public let pAndLStart: String        // "O"
    
    public init(
        assetsStart: String,      // "A",
        equityStart: String,       // "J",
        liabilitiesStart: String,  // "K",
        pAndLStart: String        // "O"
    ) {
        self.assetsStart = assetsStart
        self.equityStart = equityStart
        self.liabilitiesStart = liabilitiesStart
        self.pAndLStart = pAndLStart
    }

    public static let `default` = AlphaBounds(
        assetsStart: "A", equityStart: "J", liabilitiesStart: "K", pAndLStart: "O"
    )
}

/// Aggregated section result (balance side only)
public struct BalanceAlphaSections: Sendable {
    public let totalsRaw: [RGSAssembleSection.Balance: Decimal]
    public let leafIds:  [RGSAssembleSection.Balance: [Int]]

    public var assets: Decimal      { totalsRaw[.assets]     ?? 0 }
    public var equity: Decimal      { totalsRaw[.equity]     ?? 0 }
    public var liabilities: Decimal { totalsRaw[.liabilities] ?? 0 }
    public var diffRaw: Decimal { assets + equity + liabilities } // should be 0
}
