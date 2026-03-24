import Foundation
import Methods

public enum BalanceEquationError: LocalizedError, Sendable {
    // case sectionRootNotFound(letter: String)
    case unbalanced(diff: Decimal, assets: Decimal, equity: Decimal, liabilities: Decimal, eps: Decimal)

    public var errorDescription: String? {
        switch self {
        // case .sectionRootNotFound(let letter):
        //     return "Balance equation: No section root for letter '\(letter)'."
        case let .unbalanced(diff, a, e, l, eps):
            return "Balance equation failed: A(\(a)) + J(\(e)) + K(\(l)) = \(diff) (eps=\(eps))."
        }
    }
}

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
    public static func equation(from alpha: BalanceAlphaSections,
                         maps: RGSAssemblerResult) throws -> BalanceEquation {
        let A = try resolveSectionRoot("A", maps: maps)
        let J = try resolveSectionRoot("J", maps: maps)
        let K = try resolveSectionRoot("K", maps: maps)
        return BalanceEquation(
            assets:      (A.key, A.id, alpha.assets),
            equity:      (J.key, J.id, alpha.equity),
            liabilities: (K.key, K.id, alpha.liabilities)
        )
    }

    // /// Compute A/J/K subtotals from an already rolled-up totals table.
    // public static func balanceEquation(
    //     totals: [Int: Decimal],
    //     maps: RGSAssemblerResult,
    //     letters: (assets: String, equity: String, liabilities: String) = ("A","J","K")
    // ) throws -> BalanceEquation {
    //     let A = try resolveSectionRoot(letters.assets, maps: maps)
    //     let J = try resolveSectionRoot(letters.equity, maps: maps)
    //     let K = try resolveSectionRoot(letters.liabilities, maps: maps)
    //     return BalanceEquation(
    //         assets:      (A.key, A.id, totals[A.id] ?? 0),
    //         equity:      (J.key, J.id, totals[J.id] ?? 0),
    //         liabilities: (K.key, K.id, totals[K.id] ?? 0)
    //     )
    // }

    /// Optional assert: throws if A + J + K != 0 within epsilon.
    public static func assertBalanced(_ s: BalanceAlphaSections, eps: Decimal = 0) throws {
        let diff = s.diffRaw
        // if diff != 0 && abs((diff as NSDecimalNumber).doubleValue) > (eps as NSDecimalNumber).doubleValue {
        //     throw BalanceEquationError.unbalanced(
        //         diff: diff, assets: s.assets, equity: s.equity, liabilities: s.liabilities, eps: eps
        //     )
        // }
        if Compare.Number.Decimal.exceeds(
            diff,
            tolerance: eps,
            via: .direct
        ) {
            throw BalanceEquationError.unbalanced(
                diff: diff, assets: s.assets, equity: s.equity, liabilities: s.liabilities, eps: eps
            )
        }
    }
}
