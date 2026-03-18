public enum EntityPlaceholderKind: String, Codable, Sendable, CaseIterable {
    case asset
    case inventory
    case liability
    case equity
    case revenue
    case expense
}

public struct EntityPlaceholder: Hashable, Codable, Sendable {
    public let kind: EntityPlaceholderKind

    public init(_ kind: EntityPlaceholderKind) {
        self.kind = kind
    }

    public var loweredAlias: String {
        "\(kind.rawValue)_placeholder"
    }
}
