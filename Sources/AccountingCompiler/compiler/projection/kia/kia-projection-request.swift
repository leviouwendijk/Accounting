import Accounting
import Foundation

public struct KIAProjectionRequest: Sendable {
    public let period: KIAPeriodInput
    public let config: KIAConfig

    public init(
        period: KIAPeriodInput,
        config: KIAConfig
    ) {
        self.period = period
        self.config = config
    }
}
