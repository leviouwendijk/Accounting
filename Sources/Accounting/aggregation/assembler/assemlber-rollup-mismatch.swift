import Foundation

public struct EntityMismatchDiagnostic: Sendable {
    public struct Item: Sendable {
        public let id: Int
        public let name: String
        public let balance: Decimal
        public let entityTotal: Decimal
        public let diff: Decimal

        public init(
            id: Int,
            name: String,
            balance: Decimal,
            entityTotal: Decimal,
            diff: Decimal
        ) {
            self.id = id
            self.name = name
            self.balance = balance
            self.entityTotal = entityTotal
            self.diff = diff
        }

        public var warningLine: String {
            "warning: entity breakdown mismatch at \(name) [id=\(id)]: "
                + "balance=\(balance), entities=\(entityTotal), diff=\(diff)\n"
        }
    }

    public let items: [Item]

    public init(
        items: [Item]
    ) {
        self.items = items
    }

    public var hasWarnings: Bool {
        !items.isEmpty
    }

    @inline(__always)
    public func warn() {
        for item in items {
            fputs(item.warningLine, stderr)
        }
    }
}
