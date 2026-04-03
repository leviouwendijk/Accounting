public struct VATRoots: Sendable, Codable {
    public let payableCodes: [String]
    public let receivableCodes: [String]
    public let excludedCodes: [String]

    public init(
        payableCodes: [String],
        receivableCodes: [String],
        excludedCodes: [String] = []
    ) {
        self.payableCodes = payableCodes
        self.receivableCodes = receivableCodes
        self.excludedCodes = excludedCodes
    }
}
