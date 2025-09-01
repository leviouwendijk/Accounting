import Foundation

public struct Resolvable: Hashable, Codable, Sendable {
    public var payable: Decimal?
    public var receivable: Decimal?

    public init(payable: Decimal? = nil, receivable: Decimal? = nil) {
        self.payable = payable
        self.receivable = receivable
    }
}

public struct Mistake: Hashable, Codable, Sendable {
    public var details: String?
    public var resolvable: Resolvable?

    public init(details: String? = nil, resolvable: Resolvable? = nil) {
        self.details = details
        self.resolvable = resolvable
    }
}
