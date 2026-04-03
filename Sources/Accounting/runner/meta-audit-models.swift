import Foundation

public struct MetaAuditEquitySection: Sendable {
    public let title: String
    public let config: EquityRollforwardConfig
    public let history: [EquityPeriod]
    public let view: ClosedRange<Int>?
    public let report: EquityRollforwardReport

    public init(
        title: String,
        config: EquityRollforwardConfig,
        history: [EquityPeriod],
        view: ClosedRange<Int>?,
        report: EquityRollforwardReport
    ) {
        self.title = title
        self.config = config
        self.history = history
        self.view = view
        self.report = report
    }
}

public struct MetaAuditKIASection: Sendable {
    public let taxYear: Int
    public let result: KIAProjectionResult?
    public let warning: String?

    public init(
        taxYear: Int,
        result: KIAProjectionResult?,
        warning: String? = nil
    ) {
        self.taxYear = taxYear
        self.result = result
        self.warning = warning
    }
}

public struct MetaAuditReport: Sendable {
    public let shape: PeriodShape
    public let anchor: Date
    public let entities: EntityStore
    public let overview: AssetsOverview
    public let filingReconciliation: AssetFilingReconciliationReport
    public let acquired: AcquiredAssetsReport
    public let period: NativePeriodCompileOutput
    public let costBreakdown: CostBreakdownReport
    // public let kia: KIAProjectionResult
    public let kia: MetaAuditKIASection
    public let equity: MetaAuditEquitySection
    public let depreciation: DepreciationAuditReport

    public init(
        shape: PeriodShape,
        anchor: Date,
        entities: EntityStore,
        overview: AssetsOverview,
        filingReconciliation: AssetFilingReconciliationReport,
        acquired: AcquiredAssetsReport,
        period: NativePeriodCompileOutput,
        costBreakdown: CostBreakdownReport,
        // kia: KIAProjectionResult,
        kia: MetaAuditKIASection,
        equity: MetaAuditEquitySection,
        depreciation: DepreciationAuditReport
    ) {
        self.shape = shape
        self.anchor = anchor
        self.entities = entities
        self.overview = overview
        self.filingReconciliation = filingReconciliation
        self.acquired = acquired
        self.period = period
        self.costBreakdown = costBreakdown
        self.kia = kia
        self.equity = equity
        self.depreciation = depreciation
    }
}
