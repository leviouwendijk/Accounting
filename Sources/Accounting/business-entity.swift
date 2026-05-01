import Foundation
import Arguments

public enum BusinessEntity: String, Sendable, Codable, ArgumentValue {
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

    public var vatRoots: VATRoots {
        canonicalRoots.vat
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
