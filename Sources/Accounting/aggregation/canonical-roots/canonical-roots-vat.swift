import Foundation

public struct VATRoots: Sendable, Codable {
    /// Broad payable-side VAT families kept for audit compatibility.
    public let payableCodes: [String]

    /// Broad balance-sheet receivable VAT families kept for audit compatibility.
    public let receivableCodes: [String]

    /// Specific filing/status families.
    ///
    /// These are matched with precedence and are intended to classify a VAT line
    /// into exactly one status family:
    ///
    /// excluded
    /// → privateUse
    /// → deductible
    /// → output
    /// → receivable
    /// → payable fallback
    ///
    /// That keeps the status rollup non-overlapping.
    public let outputCodes: [String]
    public let deductibleCodes: [String]
    public let privateUseCodes: [String]

    public let excludedCodes: [String]

    public init(
        payableCodes: [String],
        receivableCodes: [String],
        outputCodes: [String] = [],
        deductibleCodes: [String] = [],
        privateUseCodes: [String] = [],
        excludedCodes: [String] = []
    ) {
        self.payableCodes = payableCodes
        self.receivableCodes = receivableCodes
        self.outputCodes = outputCodes
        self.deductibleCodes = deductibleCodes
        self.privateUseCodes = privateUseCodes
        self.excludedCodes = excludedCodes
    }
}
