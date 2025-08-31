import Foundation

public struct DepreciationConfigDraft: Sendable, Codable {
    public var schedule: DepreciationScheduleSetting
    public var acquisition: AssetAcquisitionCost
    public var residualPercentage: Decimal
    public var accountRef: AccountRef

    public init(
        schedule: DepreciationScheduleSetting,
        acquisition: AssetAcquisitionCost,
        residualPercentage: Decimal,
        accountRef: AccountRef
    ) {
        self.schedule = schedule
        self.acquisition = acquisition
        self.residualPercentage = residualPercentage
        self.accountRef = accountRef
    }

    public func resolve(
        using entities: EntityStore,
        accounts: AccountStore,
        at loc: SourceLocation? = nil
    ) throws -> DepreciationConfig {
        let node = try accounts.resolve(accountRef, at: loc)
        let a = AccountKey(node.codes.code)

        return DepreciationConfig(
            schedule: schedule,
            acquistion: acquisition,
            residualPercentage: residualPercentage,
            account: a
        )
    }
}
