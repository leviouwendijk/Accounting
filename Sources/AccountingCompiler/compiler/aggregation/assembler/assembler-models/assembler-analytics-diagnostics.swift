import Accounting
import Foundation

public struct AnalyticsBucketDiagnostic: Sendable {
    public let key: String
    public let label: String

    /// Requested primary codes for this bucket.
    public let codes: [String]

    /// Primary codes that actually resolved to a shown amount.
    public let resolvedCodes: [String]

    /// Requested fallback codes for this bucket.
    public let fallbackCodes: [String]

    /// Fallback codes that actually resolved to a shown amount.
    public let resolvedFallbackCodes: [String]

    public let usedFallback: Bool
    public let amount: Decimal?

    public init(
        key: String,
        label: String,
        codes: [String],
        resolvedCodes: [String] = [],
        fallbackCodes: [String] = [],
        resolvedFallbackCodes: [String] = [],
        usedFallback: Bool = false,
        amount: Decimal?
    ) {
        self.key = key
        self.label = label
        self.codes = codes
        self.resolvedCodes = resolvedCodes
        self.fallbackCodes = fallbackCodes
        self.resolvedFallbackCodes = resolvedFallbackCodes
        self.usedFallback = usedFallback
        self.amount = amount
    }
}

public struct AnalyticsDerivedDiagnostic: Sendable {
    public let key: String
    public let label: String
    public let formula: String
    public let amount: Decimal?

    public init(
        key: String,
        label: String,
        formula: String,
        amount: Decimal?
    ) {
        self.key = key
        self.label = label
        self.formula = formula
        self.amount = amount
    }
}

public struct AnalyticsDiagnostics: Sendable {
    public let buckets: [AnalyticsBucketDiagnostic]
    public let derived: [AnalyticsDerivedDiagnostic]

    public init(
        buckets: [AnalyticsBucketDiagnostic],
        derived: [AnalyticsDerivedDiagnostic]
    ) {
        self.buckets = buckets
        self.derived = derived
    }
}
