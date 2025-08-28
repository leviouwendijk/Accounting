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

