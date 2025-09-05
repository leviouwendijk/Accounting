import Foundation

public struct StatementRow: Codable, Sendable {
    public let code: String
    public let label: String
    public let amount: Decimal
    public let level: Int
    public let section: String
    public let parentCode: String?
    public let isTotal: Bool

    public init(
        code: String,
        label: String,
        amount: Decimal,
        level: Int,
        section: String,
        parentCode: String? = nil,
        isTotal: Bool = false
    ) {
        self.code = code
        self.label = label
        self.amount = amount
        self.level = level
        self.section = section
        self.parentCode = parentCode
        self.isTotal = isTotal
    }
}
