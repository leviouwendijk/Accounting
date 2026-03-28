public struct EquityPresentation: Presentation {
    public typealias Input = HistoryPresentationInput
    public typealias Output = EquityRollforwardReport

    public static let id = "equity"
    public static let title = "Equity rollforward (backsolved)"

    public let reportTitle: String
    public let config: EquityRollforwardConfig

    public init(
        reportTitle: String = "Equity rollforward (backsolved)",
        config: EquityRollforwardConfig = .init()
    ) {
        self.reportTitle = reportTitle
        self.config = config
    }

    public func build(from input: Input) throws -> Output {
        // try buildOwnerEquityRollforwardReport(
        try OwnerEquity.Rollforward.report(
            title: reportTitle,
            allPeriods: input.history,
            chart: input.chart,
            entities: input.entities,
            view: input.view,
            config: config
        )
    }
}
