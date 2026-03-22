import Foundation

public enum KIAQualificationReason: Sendable, Hashable {
    case missingDepreciation
    case missingAcquisitionProfile
    case missingAcquisitionCost
    case outsideTaxYear
    case invalidShareConfiguration(String)
}
