import Foundation

public enum KIAQualificationReason: Sendable, Hashable {
    case missingDepreciation
    case missingProfile
    case missingCommissionDate
    case missingAcquisitionCost
    case belowMinimumAssetAmount(Decimal)
    case outsideTaxYear(actualYear: Int?)
    case invalidShareConfiguration(String)
    case notAssetCandidate
}
