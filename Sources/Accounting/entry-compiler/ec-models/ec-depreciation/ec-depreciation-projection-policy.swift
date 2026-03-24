import Foundation

public struct DepreciationProjectionPolicy: Sendable {
    public let startDate: Date
    public let startConvention: DepreciationStartConvention

    public init(
        startDate: Date,
        startConvention: DepreciationStartConvention
    ) {
        self.startDate = startDate
        self.startConvention = startConvention
    }
}

public extension DepreciationProjectionPolicy {
    @inline(__always)
    static func canonical(
        for key: EntityKey,
        entity: EntityDef,
        config: DepreciationConfig
    ) throws -> DepreciationProjectionPolicy {
        let profileAccess = try DepreciationProfileAccess.resolve(
            for: key,
            entity: entity,
            fallbackSchedule: config.schedule,
            fallbackAcquisition: config.acquistion
        )

        return DepreciationProjectionPolicy(
            startDate: profileAccess.commissionDate,
            startConvention: .firstFullMonth
        )
    }
}
