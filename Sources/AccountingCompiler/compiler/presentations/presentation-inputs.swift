import Accounting
public struct BundlePresentationInput: BundlePresentableInput {
    public let chart: CompiledChart
    public let bundle: StatementBundle
    public let entities: EntityStore?

    public init(
        chart: CompiledChart,
        bundle: StatementBundle,
        entities: EntityStore? = nil
    ) {
        self.chart = chart
        self.bundle = bundle
        self.entities = entities
    }
}

public struct HistoryPresentationInput: HistoryPresentableInput {
    public let chart: CompiledChart
    public let history: [EquityPeriod]
    public let entities: EntityStore
    public let view: ClosedRange<Int>?

    public init(
        chart: CompiledChart,
        history: [EquityPeriod],
        entities: EntityStore,
        view: ClosedRange<Int>? = nil
    ) {
        self.chart = chart
        self.history = history
        self.entities = entities
        self.view = view
    }
}
