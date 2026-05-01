import Accounting
import Foundation

public struct DepreciationAuditRunner {
    public struct Options: Sendable {
        public var granularity: DepreciationGranularity = .monthly
        public var tolerance: Decimal = 0.01
        public var tolerateAggregateIntraQuarter: Bool = true
        public var calendar: Calendar = .init(identifier: .gregorian)

        public init() {}

        public init(
            granularity: DepreciationGranularity = .monthly,
            tolerance: Decimal = 0.01,
            tolerateAggregateIntraQuarter: Bool = true,
            calendar: Calendar = .init(identifier: .gregorian)
        ) {
            self.granularity = granularity
            self.tolerance = tolerance
            self.tolerateAggregateIntraQuarter = tolerateAggregateIntraQuarter
            self.calendar = calendar
        }
    }

    /// Low-level: you already have compiled stores + resolved entries.
    /// Runs: resolve entity dep configs → project → audit.
    public static func run(
        entities: EntityStore,
        accounts: AccountStore,
        resolvedEntries: [ResolvedEntry],
        through auditEnd: Date? = nil,
        options: Options = .init()
    ) throws -> DepreciationAuditReport {
        // 0) Resolve entity depreciation drafts → final configs
        let entitiesResolved = try DepreciationResolutionPass.run(on: entities, using: accounts)

        // 1) Collect resolved configs (EntityKey → DepreciationConfig)
        let depConfigs = try entitiesResolved.collectDepreciationOrThrow()

        // 2) Decide horizon
        let end = auditEnd ?? DepreciationAuditHorizon.endOfMonth(using: resolvedEntries, calendar: options.calendar)

        // 3) Projections
        let projections = try entitiesResolved.projectDepreciation(
            through: end,
            granularity: options.granularity,
            calendar: options.calendar
        )

        // 4) Audit
        let report = resolvedEntries.auditDepreciation(
            projections: projections,
            configs: depConfigs,
            granularity: options.granularity,
            calendar: options.calendar,
            tolerance: options.tolerance,
            tolerateAggregateIntraQuarter: options.tolerateAggregateIntraQuarter,
            horizonEnd: end,
            dateOf: { re in
                if case let .absolute(d) = re.date { return d }
                return Date()
            }
        )
        return report
    }
}

public extension DepreciationAuditRunner {
    static func run(
        projectRoot: URL,
        setting: CompileDriveSetting = .init(
            entities: true, accounts: true, transactions: true, entries: true, assertion: true
        ),
        verbose: Bool = false,
        through auditEnd: Date? = nil,
        options: Options = .init()
    ) throws -> DepreciationAuditReport {
        let result = try EntryCompileDriver.compile(
            projectRoot: projectRoot,
            setting: setting,
            verbose: verbose
        )
        return try Self.run(
            entities: result.entities,
            accounts: result.accounts,
            resolvedEntries: result.resolved,
            through: auditEnd,
            options: options
        )
    }
}
