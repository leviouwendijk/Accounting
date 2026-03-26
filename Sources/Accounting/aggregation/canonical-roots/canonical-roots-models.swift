import Foundation

public struct CanonicalRoots: Sendable, Codable {
    public let autoCloseTargets: AutoCloseTargets
    public let periodOpeningRouting: PeriodOpeningRouting
    public let capital: CapitalRoots
    public let analytics: AnalyticsRoots

    public init(
        autoCloseTargets: AutoCloseTargets,
        periodOpeningRouting: PeriodOpeningRouting,
        capital: CapitalRoots,
        analytics: AnalyticsRoots
    ) {
        self.autoCloseTargets = autoCloseTargets
        self.periodOpeningRouting = periodOpeningRouting
        self.capital = capital
        self.analytics = analytics
    }
}
