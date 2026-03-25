import Foundation

public enum AssetAcquisitionValidationSeverity: String, Codable, Sendable {
    case info
    case warning
    case error
}

public struct AssetAcquisitionValidationIssue: Codable, Sendable {
    public let severity: AssetAcquisitionValidationSeverity
    public let message: String

    public init(
        severity: AssetAcquisitionValidationSeverity,
        message: String
    ) {
        self.severity = severity
        self.message = message
    }
}

public struct AssetAcquisitionLedgerMatch: Codable, Sendable {
    public let entryId: Int?
    public let date: Date
    public let amount: Decimal
    public let direction: Direction

    public init(
        entryId: Int?,
        date: Date,
        amount: Decimal,
        direction: Direction
    ) {
        self.entryId = entryId
        self.date = date
        self.amount = amount
        self.direction = direction
    }
}

public struct AssetValidationRow: Sendable {
    public let entityKey: EntityKey
    public let displayName: String
    public let details: String?

    public let acquisitionDate: Date?
    public let commissionDate: Date?

    public let acquisitionEntry: Int?
    public let acquisitionAccount: AccountRef?
    public let acquisitionCost: Decimal?

    public let matchedLedgerAmount: Decimal
    public let ledgerMatches: [AssetAcquisitionLedgerMatch]

    public let issues: [AssetAcquisitionValidationIssue]

    public init(
        entityKey: EntityKey,
        displayName: String,
        details: String?,
        acquisitionDate: Date?,
        commissionDate: Date?,
        acquisitionEntry: Int?,
        acquisitionAccount: AccountRef?,
        acquisitionCost: Decimal?,
        matchedLedgerAmount: Decimal,
        ledgerMatches: [AssetAcquisitionLedgerMatch],
        issues: [AssetAcquisitionValidationIssue]
    ) {
        self.entityKey = entityKey
        self.displayName = displayName
        self.details = details
        self.acquisitionDate = acquisitionDate
        self.commissionDate = commissionDate
        self.acquisitionEntry = acquisitionEntry
        self.acquisitionAccount = acquisitionAccount
        self.acquisitionCost = acquisitionCost
        self.matchedLedgerAmount = matchedLedgerAmount
        self.ledgerMatches = ledgerMatches
        self.issues = issues
    }

    public var delta: Decimal? {
        guard let acquisitionCost else {
            return nil
        }

        return matchedLedgerAmount - acquisitionCost
    }

    public var hasIssues: Bool {
        !issues.isEmpty
    }

    public var highestSeverity: AssetAcquisitionValidationSeverity? {
        if issues.contains(where: { $0.severity == .error }) {
            return .error
        }

        if issues.contains(where: { $0.severity == .warning }) {
            return .warning
        }

        if issues.contains(where: { $0.severity == .info }) {
            return .info
        }

        return nil
    }
}

public struct AssetValidationReport: PresentableOutput {
    public let rows: [AssetValidationRow]
    public let diagnosticsCounts: [String: Int]

    public init(
        rows: [AssetValidationRow],
        diagnosticsCounts: [String: Int]
    ) {
        self.rows = rows
        self.diagnosticsCounts = diagnosticsCounts
    }

    public var flaggedRows: [AssetValidationRow] {
        rows.filter(\.hasIssues)
    }
}
