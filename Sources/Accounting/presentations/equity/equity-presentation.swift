public struct EquityPresentation: Presentation {
    public typealias Input = HistoryPresentationInput
    public typealias Output = EquityRollforwardReport

    public static let id = "equity"
    public static let title = "IB equity rollforward"

    public let reportTitle: String
    public let config: EquityRollforwardConfig

    public init(
        reportTitle: String = "IB equity rollforward (owner split, backsolved)",
        config: EquityRollforwardConfig = .init()
    ) {
        self.reportTitle = reportTitle
        self.config = config
    }

    public func build(from input: Input) throws -> Output {
        try buildOwnerEquityRollforwardReport(
            title: reportTitle,
            allPeriods: input.history,
            chart: input.chart,
            entities: input.entities,
            view: input.view,
            config: config
        )
    }
}
