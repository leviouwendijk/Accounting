import Foundation

public enum BusinessEntity: Sendable, Codable {
    case vof

    public var canonicalRoots: CanonicalRoots {
        switch self {
        case .vof:
            return .vof
        }
    }

    public var analyticsRoots: AnalyticsRoots {
        canonicalRoots.analytics
    }

    public var capitalRoots: CapitalRoots {
        canonicalRoots.capital
    }

    public func autoCloseTargets() -> AutoCloseTargets {
        canonicalRoots.autoCloseTargets
    }

    public var periodOpeningRouting: PeriodOpeningRouting {
        canonicalRoots.periodOpeningRouting
    }

    public var profitShareCode: String {
        canonicalRoots.capital.profitShareCode
    }
}
