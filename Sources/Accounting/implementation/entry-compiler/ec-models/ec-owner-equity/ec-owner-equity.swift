import Foundation

public struct OwnershipPercentage: Codable, Sendable {
    public let date: Date
    public let percentage: Decimal
    public let details: String?
}

public struct OwnerEquity: Codable, Sendable {
    public let initial: OwnershipPercentage
    public let changes: [OwnershipPercentage]

    public func percentage(on d: Date) -> Decimal {
        let all = ([initial] + changes).sorted{ $0.date < $1.date }
        return all.last(where:{ $0.date <= d })?.percentage ?? initial.percentage
    }
}
