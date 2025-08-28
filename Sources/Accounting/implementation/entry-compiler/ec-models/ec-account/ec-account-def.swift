import Foundation

public struct AccountDef: Codable, Sendable {
    public let code: String
    public var label: String?
    public var direction: Direction?
    public var level: Int?
    public var identifiers: RGSIdentifiers?
    public var applicability: Applicability?

    public init(
        code: String,
        label: String? = nil,
        direction: Direction? = nil,
        level: Int? = nil,
        identifiers: RGSIdentifiers? = nil,
        applicability: Applicability? = nil
    ) {
        self.code = code
        self.label = label
        self.direction = direction
        self.level = level
        self.identifiers = identifiers
        self.applicability = applicability
    }
}
