import Foundation

public struct DepreciationConfig: Sendable, Codable {
    public var schedule: DepreciationScheduleSetting
    public var acquistion: AssetAcquisitionCost
    public var residual: DepreciationResidualValue
    public let account: AccountKey
    public let contra: AccountKey

    public init(
        schedule: DepreciationScheduleSetting,
        acquistion: AssetAcquisitionCost,
        residualPercentage: Decimal,
        account: AccountKey,
        contra: AccountKey
    ) {
        self.schedule = schedule
        self.acquistion = acquistion
        self.residual = DepreciationResidualValue(
            percent: residualPercentage,
            acquisitionCost: acquistion
        )
        self.account = account
        self.contra = contra
    }
    
    public init(
        method: DepreciationMethod,
        acquisitionCost: AssetAcquisitionCost,
        usefulLifeYears: Decimal,
        residualPercentage: Decimal,
        effectiveDate: Date,
        account: AccountKey,
        contra: AccountKey
    ) {
        self.schedule = DepreciationScheduleSetting(
            method: method,
            usefulLifeYears: usefulLifeYears,
            effectiveDate: effectiveDate
        )
        self.acquistion = acquisitionCost
        self.residual = DepreciationResidualValue(
            percent: residualPercentage,
            acquisitionCost: acquisitionCost
        )
        self.account = account
        self.contra = contra
    }

    public func depreciableBase() -> Decimal {
        let base = AccountingMoney.round(acquistion.cost - residual.amount)
        return base > 0 ? base : 0
    }
}

extension DepreciationConfig {
    public var usefulLifeMonths: Int {
        guard schedule.usefulLifeYears > 0 else {
            return 0
        }

        let months = schedule.usefulLifeYears * 12
        let doubleVal = (months as NSDecimalNumber).doubleValue
        return Int(ceil(doubleVal))
    }

    public func validate() throws {
        if schedule.usefulLifeYears <= 0 {
            throw DepreciationValidationError.nonPositiveUsefulLife
        }

        let p = residual.percent
        if p < 0 {
            throw DepreciationValidationError.invalidPercent(p)
        }

        let rv = residual.amount
        if rv < 0 {
            throw DepreciationValidationError.negativeResidual
        }

        if rv > acquistion.cost {
            throw DepreciationValidationError.residualExceedsCost(
                residual: rv,
                cost: acquistion.cost
            )
        }
    }
}
