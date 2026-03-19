import Foundation

public struct DepreciationConfigDraft: Sendable, Codable {
    public var schedule: DepreciationScheduleSetting
    public var acquisition: AssetAcquisitionCost
    public var residualPercentage: Decimal
    public var accountRef: AccountRef
    public var contraRef: AccountRef

    public init(
        schedule: DepreciationScheduleSetting,
        acquisition: AssetAcquisitionCost,
        residualPercentage: Decimal,
        accountRef: AccountRef,
        contraRef: AccountRef
    ) {
        self.schedule = schedule
        self.acquisition = acquisition
        self.residualPercentage = residualPercentage
        self.accountRef = accountRef
        self.contraRef = contraRef
    }

    public func resolve(
        using entities: EntityStore,
        accounts: AccountStore,
        at loc: SourceLocation? = nil
    ) throws -> DepreciationConfig {
        let expenseNode = try accounts.resolve(accountRef, at: loc)
        let expense = AccountKey(expenseNode.codes.code)

        let contraNode = try accounts.resolve(contraRef, at: loc)
        let contra = AccountKey(contraNode.codes.code)

        return DepreciationConfig(
            schedule: schedule,
            acquistion: acquisition,
            residualPercentage: residualPercentage,
            account: expense,
            contra: contra
        )
    }
}
