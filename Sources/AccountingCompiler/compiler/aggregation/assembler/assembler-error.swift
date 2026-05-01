import Accounting
import Foundation

public enum RGSAssemblerError: LocalizedError, Sendable {
    case missingIndex
    case seedTotalsNotZero(Decimal)
    case unbalanced(diff: Decimal, assets: Decimal, equity: Decimal, liabilities: Decimal, eps: Decimal)

    public var errorDescription: String? {
        switch self {
        case .missingIndex:
            return "RGSAssembler: Missing index on compiled chart."
        case .seedTotalsNotZero(let sum):
            return "RGSAssembler: Seed totals do not sum to zero (\(sum))."
        case .unbalanced(let diff, let assets, let equity, let liabilities, let eps):
            return "RGSAssembler: Unbalanced (diff: \(diff); assets: \(assets); equity: \(equity); liabilities: \(liabilities); eps: \(eps))."
        }
    }
}
