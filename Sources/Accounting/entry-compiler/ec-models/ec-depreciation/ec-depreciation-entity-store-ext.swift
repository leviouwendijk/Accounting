import Foundation

public enum DepreciationCollectionError: LocalizedError {
    case unresolvedConfigs([EntityKey])

    public var errorDescription: String? {
        switch self {
        case .unresolvedConfigs(let keys):
            let list = keys.map { $0.identifier(displaying: .fullchain) }.joined(separator: ", ")
            return "Unresolved depreciation configs for: \(list)"
        }
    }
}

public extension EntityStore {
    func pairs() -> AnySequence<(EntityKey, EntityDef)> {
        AnySequence(self.byFull.map { ($0.key, $0.value) })
    }

    var depreciationMap: [EntityKey: DepreciationConfig] {
        var out: [EntityKey: DepreciationConfig] = [:]
        for (k, def) in pairs() {
            if let cfg = def.depreciation { out[k] = cfg }
        }
        return out
    }

    func collectDepreciationOrThrow() throws -> [EntityKey: DepreciationConfig] {
        let unresolved = pairs()
            .compactMap { (k, def) in def.depreciationDraft != nil ? k : nil }

        if !unresolved.isEmpty {
            throw DepreciationCollectionError.unresolvedConfigs(unresolved)
        }
        return depreciationMap
    }

    // // NOTE: 
    // // not using defaultTimeZone yet, from settings
    // func projectDepreciation(
    //     through endDate: Date,
    //     granularity: DepreciationGranularity = .monthly,
    //     calendar: Calendar = .init(identifier: .gregorian)
    // ) throws -> [EntityKey: [DepreciationSlice]] {
    //     let map = try collectDepreciationOrThrow()
    //     var out: [EntityKey: [DepreciationSlice]] = [:]
    //     for (k, cfg) in map {
    //         out[k] = cfg.project(through: endDate, granularity: granularity, calendar: calendar)
    //     }
    //     return out
    // }
    func projectDepreciation(
        through endDate: Date,
        granularity: DepreciationGranularity = .monthly,
        calendar: Calendar = .init(identifier: .gregorian)
    ) throws -> [EntityKey: [DepreciationSlice]] {
        let map = try collectDepreciationOrThrow()
        var out: [EntityKey: [DepreciationSlice]] = [:]

        for (k, cfg) in map {
            guard let entity = byFull[k] else {
                out[k] = cfg.project(
                    through: endDate,
                    startDate: cfg.schedule.effectiveDate,
                    startConvention: .exactDate,
                    granularity: granularity,
                    calendar: calendar
                )
                continue
            }

            let profileAccess = try DepreciationProfileAccess.resolve(
                for: k,
                entity: entity,
                fallbackSchedule: cfg.schedule,
                fallbackAcquisition: cfg.acquistion
            )

            out[k] = cfg.project(
                through: endDate,
                startDate: profileAccess.commissionDate,
                startConvention: .firstFullMonth,
                granularity: granularity,
                calendar: calendar
            )
        }

        return out
    }
}
