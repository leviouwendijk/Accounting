import Accounting
import Foundation

public struct PeriodAssembleResultPeriod: Sendable {
    public let range: PeriodWindow
    public let bundle: StatementBundle
}

public struct PeriodAssembleResult: Sendable {
    // public let current: StatementBundle
    // public let previous: StatementBundle?

    public let current: PeriodAssembleResultPeriod
    public let previous: PeriodAssembleResultPeriod?
}
