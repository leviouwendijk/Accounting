import Foundation

public struct DepreciationConfigDraft: Sendable, Codable {
    // @available(*, deprecated, message: "Use entity.unit.profile.commission_date instead.")
    // public var schedule: DepreciationScheduleSetting?

    // @available(*, deprecated, message: "Use entity.unit.profile.valuation.acquisition_cost instead.")
    // public var acquisition: AssetAcquisitionCost?

    public var residualPercentage: Decimal
    public var accountRef: AccountRef
    public var contraRef: AccountRef

    public var method: DepreciationMethod
    public var usefulLifeYears: Decimal

    public init(
        // schedule: DepreciationScheduleSetting? = nil,
        // acquisition: AssetAcquisitionCost? = nil,
        residualPercentage: Decimal,
        accountRef: AccountRef,
        contraRef: AccountRef,
        method: DepreciationMethod,
        usefulLifeYears: Decimal
    ) {
        // self.schedule = schedule
        // self.acquisition = acquisition
        self.residualPercentage = residualPercentage
        self.accountRef = accountRef
        self.contraRef = contraRef
        self.method = method
        self.usefulLifeYears = usefulLifeYears
    }

    public func resolve(
        for key: EntityKey,
        entity: EntityDef,
        accounts: AccountStore,
        at loc: SourceLocation? = nil
    ) throws -> DepreciationConfig {
        let expenseNode = try accounts.resolve(accountRef, at: loc)
        let expense = AccountKey(expenseNode.codes.code)

        let contraNode = try accounts.resolve(contraRef, at: loc)
        let contra = AccountKey(contraNode.codes.code)

        let profile = try DepreciationProfileAccess.resolve(
            for: key,
            entity: entity,
            // fallbackSchedule: schedule,
            // fallbackAcquisition: acquisition
        )

        let resolvedSchedule = DepreciationScheduleSetting(
            method: method,
            usefulLifeYears: usefulLifeYears,
            effectiveDate: profile.commissionDate
        )

        return DepreciationConfig(
            schedule: resolvedSchedule,
            acquistion: profile.acquisition,
            residualPercentage: residualPercentage,
            account: expense,
            contra: contra
        )
    }
}
