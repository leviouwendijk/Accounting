import Foundation

public enum BusinessEntity: Sendable, Codable {
    case vof

    public func autoCloseTargets() -> AutoCloseTargets {
        var netIncomeCode: String
        var retainedEarningsCode: String

        switch self {
        case .vof:
            netIncomeCode        =  "WNerKapKap"
            retainedEarningsCode =  "BEivKapOndAow" // instead of level 4 BEivKapOnd
        }

        return AutoCloseTargets(
            netIncomeCode        :  netIncomeCode,
            retainedEarningsCode :  retainedEarningsCode
        )
    }
}
