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

public struct OwnershipSlice: Sendable {
    public let entityId: Int      // used in AccEntKey
    public let percent: Decimal   // 0…1 fraction (normalized)

    public init(entityId: Int, percent: Decimal) {
        self.entityId = entityId
        self.percent = percent
    }
}
