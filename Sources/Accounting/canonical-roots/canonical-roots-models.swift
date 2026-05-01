import Foundation

public struct CanonicalRoots: Sendable, Codable {
    public let autoCloseTargets: AutoCloseTargets
    public let periodOpeningRouting: PeriodOpeningRouting
    public let capital: CapitalRoots
    public let analytics: AnalyticsRoots
    public let vat: VATRoots

    public init(
        autoCloseTargets: AutoCloseTargets,
        periodOpeningRouting: PeriodOpeningRouting,
        capital: CapitalRoots,
        analytics: AnalyticsRoots,
        vat: VATRoots
    ) {
        self.autoCloseTargets = autoCloseTargets
        self.periodOpeningRouting = periodOpeningRouting
        self.capital = capital
        self.analytics = analytics
        self.vat = vat
    }
}
