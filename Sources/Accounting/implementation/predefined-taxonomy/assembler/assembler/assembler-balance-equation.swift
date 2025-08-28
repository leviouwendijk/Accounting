import Foundation

public struct BalanceEquation: Sendable {
    public let assets:      (key: String, id: Int, raw: Decimal)
    public let equity:      (key: String, id: Int, raw: Decimal)
    public let liabilities: (key: String, id: Int, raw: Decimal)

    public init(
        assets: (key: String, id: Int, raw: Decimal),
        equity: (key: String, id: Int, raw: Decimal),
        liabilities: (key: String, id: Int, raw: Decimal)
    ) {
        self.assets = assets
        self.equity = equity
        self.liabilities = liabilities
    }

    public var diffRaw: Decimal { assets.raw + equity.raw + liabilities.raw } // should be 0
}

extension RGSAssembler {
    /// Resolve a section root by letter, trying "B.<L>" then "<L>".
    private static func resolveSectionRoot(
        _ letter: String,
        maps: RGSAssemblerResult
    ) throws -> (key: String, id: Int) {
        let candidates = ["B.\(letter)", letter]
        for k in candidates {
            if let id = maps.keyToId[k] { return (k, id) }
        }
        throw BalanceEquationError.sectionRootNotFound(letter: letter)
    }

    /// Compute A/J/K subtotals from an already rolled-up totals table.
    public static func balanceEquation(
        totals: [Int: Decimal],
        maps: RGSAssemblerResult,
        letters: (assets: String, equity: String, liabilities: String) = ("A","J","K")
    ) throws -> BalanceEquation {
        let A = try resolveSectionRoot(letters.assets, maps: maps)
        let J = try resolveSectionRoot(letters.equity, maps: maps)
        let K = try resolveSectionRoot(letters.liabilities, maps: maps)
        return BalanceEquation(
            assets:      (A.key, A.id, totals[A.id] ?? 0),
            equity:      (J.key, J.id, totals[J.id] ?? 0),
            liabilities: (K.key, K.id, totals[K.id] ?? 0)
        )
    }

    /// Optional assert: throws if A + J + K != 0 within epsilon.
    public static func assertBalanced(
        _ eq: BalanceEquation,
        eps: Decimal = 0
    ) throws {
        let diff = eq.diffRaw
        if diff != 0 && abs((diff as NSDecimalNumber).doubleValue) > (eps as NSDecimalNumber).doubleValue {
            throw BalanceEquationError.unbalanced(
                diff: diff,
                assets: eq.assets.raw,
                equity: eq.equity.raw,
                liabilities: eq.liabilities.raw,
                eps: eps
            )
        }
    }
}
