import Foundation

public enum RGSAssemblerError: LocalizedError, Sendable {
    case missingIndex
    case seedTotalsNotZero(Decimal)

    public var errorDescription: String? {
        switch self {
        case .missingIndex:
            return "RGSAssembler: Missing index on compiled chart."
        case .seedTotalsNotZero(let sum):
            return "RGSAssembler: Seed totals do not sum to zero (\(sum))."
        }
    }
}

public enum BalanceEquationError: LocalizedError, Sendable {
    case sectionRootNotFound(letter: String)
    case unbalanced(diff: Decimal, assets: Decimal, equity: Decimal, liabilities: Decimal, eps: Decimal)

    public var errorDescription: String? {
        switch self {
        case .sectionRootNotFound(let letter):
            return "Balance equation: No section root for letter '\(letter)'."
        case let .unbalanced(diff, a, e, l, eps):
            return "Balance equation failed: A(\(a)) + J(\(e)) + K(\(l)) = \(diff) (eps=\(eps))."
        }
    }
}
