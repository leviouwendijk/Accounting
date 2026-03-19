public struct EquityReportPeriod: Sendable {
    public let label: String
    public let rows: PeriodRollforward

    public init(
        label: String,
        rows: PeriodRollforward
    ) {
        self.label = label
        self.rows = rows
    }
}

public struct EquityRollforwardReport: PresentableOutput {
    public let title: String
    public let periods: [EquityReportPeriod]
    public let anchorMessages: [String]
    
    public init(
        title: String,
        periods: [EquityReportPeriod],
        anchorMessages: [String]
    ) {
        self.title = title
        self.periods = periods
        self.anchorMessages = anchorMessages
    }
}
