import Foundation

public enum KIAQualificationReason: Sendable, Hashable {
    case missingDepreciation
    case missingEffectiveDate
    case missingAcquisitionCost
    case belowMinimumAssetAmount(Decimal)
    case outsideTaxYear
    case invalidShareConfiguration(String)
}
