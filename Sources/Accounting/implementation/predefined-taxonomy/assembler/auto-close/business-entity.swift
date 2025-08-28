import Foundation

public enum BusinessEntity: Sendable, Codable {
    case vof

    public func autoCloseTargets() -> AutoCloseTargets {
        var netIncomeCode: String
        var retainedEarningsCode: String

        switch self {
        case .vof:
            netIncomeCode        =  "WNerKapKap"
            retainedEarningsCode =  "BEivKapOnd"
        }

        return AutoCloseTargets(
            netIncomeCode        :  netIncomeCode,
            retainedEarningsCode :  retainedEarningsCode
        )
    }
}
