import Foundation

public enum DepreciationValidationError: Error, LocalizedError, Sendable {
    case missingUsefulLife
    case nonPositiveUsefulLife
    case invalidPercent(Decimal)        // raw input (0–1 or 0–100 accepted)
    case negativeResidual
    case residualExceedsCost(residual: Decimal, cost: Decimal)

    public var errorDescription: String? {
        switch self {
        case .missingUsefulLife             :  return "Useful life is required."
        case .nonPositiveUsefulLife         :  return "Useful life must be > 0."
        case let .invalidPercent(p)         :  return "Residual percent \(p) is invalid (use 0–1 or 0–100)."
        case .negativeResidual              :  return "Residual value cannot be negative."
        case let .residualExceedsCost(r, c) :  return "Residual \(r) exceeds cost \(c)."
        }
    }
}
