import Accounting
import Foundation

public enum AssetFilingReconciliationMetric: String, Codable, Sendable, CaseIterable {
    case closingGrossCost
    case periodInvestments
    case closingCarryingAmount

    public var label: String {
        switch self {
        case .closingGrossCost:
            return "Closing gross cost"
        case .periodInvestments:
            return "Investments in period"
        case .closingCarryingAmount:
            return "Closing carrying amount"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .closingGrossCost:
            return 0
        case .periodInvestments:
            return 1
        case .closingCarryingAmount:
            return 2
        }
    }
}

public struct AssetFilingReconciliationRow: Sendable {
    public let section: AssetsOverviewSection
    public let metric: AssetFilingReconciliationMetric
    public let projected: Decimal
    public let ledger: Decimal
    public let difference: Decimal
    public let ledgerSelector: String
    public let matchedCodes: [String]
    public let notes: [String]
    public let passed: Bool

    public init(
        section: AssetsOverviewSection,
        metric: AssetFilingReconciliationMetric,
        projected: Decimal,
        ledger: Decimal,
        difference: Decimal,
        ledgerSelector: String,
        matchedCodes: [String],
        notes: [String],
        passed: Bool
    ) {
        self.section = section
        self.metric = metric
        self.projected = projected
        self.ledger = ledger
        self.difference = difference
        self.ledgerSelector = ledgerSelector
        self.matchedCodes = matchedCodes
        self.notes = notes
        self.passed = passed
    }
}

public struct AssetFilingReconciliationReport: PresentableOutput {
    public let period: PeriodWindow
    public let tolerance: Decimal
    public let rows: [AssetFilingReconciliationRow]
    public let uncheckedSections: [AssetsOverviewSection]

    public init(
        period: PeriodWindow,
        tolerance: Decimal,
        rows: [AssetFilingReconciliationRow],
        uncheckedSections: [AssetsOverviewSection]
    ) {
        self.period = period
        self.tolerance = tolerance
        self.rows = rows
        self.uncheckedSections = uncheckedSections
    }

    public var checkCount: Int {
        rows.count
    }

    public var failureCount: Int {
        rows.filter { !$0.passed }.count
    }
}
