import Foundation

public struct FinancialAverages: Sendable {
    public let metrics: [FinancialAverageMetric]

    public init(
        metrics: [FinancialAverageMetric]
    ) {
        self.metrics = metrics
    }

    public var isEmpty: Bool {
        metrics.isEmpty
    }
}

public struct FinancialAverageMetric: Sendable {
    public let key: String
    public let label: String
    public let rows: [FinancialAverageRow]

    public init(
        key: String,
        label: String,
        rows: [FinancialAverageRow]
    ) {
        self.key = key
        self.label = label
        self.rows = rows
    }
}

public struct FinancialAverageRow: Sendable {
    public let unit: FinancialPeriodUnit
    public let value: Decimal

    public init(
        unit: FinancialPeriodUnit,
        value: Decimal
    ) {
        self.unit = unit
        self.value = value
    }
}
