import Foundation

public struct DepreciationConfig: Sendable, Codable {
    public var schedule: DepreciationScheduleSetting
    public var acquistion: AssetAcquisitionCost
    public var residual: DepreciationResidualValue
    
    public init(
        schedule: DepreciationScheduleSetting,
        acquistion: AssetAcquisitionCost,
        residualPercentage: Decimal
    ) {
        self.schedule = schedule
        self.acquistion = acquistion
        self.residual = DepreciationResidualValue(
            percent: residualPercentage,
            acquisitionCost: acquistion
        )
    }
    
    public init(
        method: DepreciationMethod,
        acquisitionCost: AssetAcquisitionCost,
        usefulLifeYears: Decimal,
        residualPercentage: Decimal,   
        effectiveDate: Date
    ) {
        self.schedule = DepreciationScheduleSetting(
            method: method,
            usefulLifeYears: usefulLifeYears,
            effectiveDate: effectiveDate
        )
        self.acquistion = acquisitionCost
        self.residual = DepreciationResidualValue(
            percent: residualPercentage,
            acquisitionCost: acquistion
        )
    }

    public func depreciableBase() -> Decimal {
        let base = acquistion.cost - residual.amount
        return base > 0 ? base : 0
    }
}

extension DepreciationConfig {
    public var usefulLifeMonths: Int {
        guard schedule.usefulLifeYears > 0 else { return 0 }
        // e.g. 3.1 years => ceil(37.2) = 38 months
        let months = (schedule.usefulLifeYears * 12)
        // round up to the next whole month
        let doubleVal = (months as NSDecimalNumber).doubleValue
        return Int(ceil(doubleVal))
    }

    public func validate() throws {
        if schedule.usefulLifeYears <= 0 { throw DepreciationValidationError.nonPositiveUsefulLife }

        let p = residual.percent
        if p < 0 { throw DepreciationValidationError.invalidPercent(p) }

        let rv = residual.amount
        if rv < 0 { throw DepreciationValidationError.negativeResidual }
        if rv > acquistion.cost { throw DepreciationValidationError.residualExceedsCost(residual: rv, cost: acquistion.cost) }
    }
}
