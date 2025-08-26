import Foundation

public struct AggregationPlan: Codable, Sendable {
    public let statement: StatementDef
    public let partition: PartitionSpec?          // e.g., keys:[.entity], requireBalanced:true for B/S
    public let filters: [DimensionFilter]         // e.g., entityClass IN ["objects"]
    public let includePreviousPeriods: Bool       // you already keep this in settings :contentReference[oaicite:7]{index=7}
}

public struct Aggregator {
    public let accounts: AccountStore
    public let plan: AggregationPlan

    public init(accounts: AccountStore, plan: AggregationPlan) {
        self.accounts = accounts
        self.plan = plan
    }

    public func buildCube(
        entries: [ResolvedEntry],
        previousEntries: [ResolvedEntry] = []
    ) throws -> StatementCube {

        // 1) Compile row matchers from StatementDef
        let matchers = try compileMatchers(for: plan.statement)

        // 2) Normalize entries -> postings
        var postingsNow: [NormalizedPosting] = []
        postingsNow.reserveCapacity(entries.reduce(0) { $0 + $1.lines.count })

        for e in entries {
            for ln in e.lines {
                postingsNow.append(try normalize(e, ln, accounts: accounts))
            }
        }

        var postingsPrev: [NormalizedPosting] = []
        if plan.includePreviousPeriods {
            for e in previousEntries {
                for ln in e.lines {
                    postingsPrev.append(try normalize(e, ln, accounts: accounts))
                }
            }
        }

        // 3) Apply dimension filters
        postingsNow  = postingsNow.filter { posting in evaluateFilters(plan.filters, on: posting.dims) }
        postingsPrev = postingsPrev.filter { posting in evaluateFilters(plan.filters, on: posting.dims) }

        // 4) Bucket into a raw cube: (rowId, partition, periodIndex) -> Decimal
        var cube: StatementCube = [:]
        bucket(postingsNow,  into: &cube, periodIndex: 0, matchers: matchers, partition: plan.partition)
        if plan.includePreviousPeriods {
            bucket(postingsPrev, into: &cube, periodIndex: 1, matchers: matchers, partition: plan.partition)
        }

        // 5) Apply materiality per row (per period, and within partition groups)
        applyMateriality(in: &cube, statement: plan.statement, partition: plan.partition)

        // 6) Optional: ensure partition-level balance for Balance Sheet views
        if plan.statement.kind == .balance, let ps = plan.partition, ps.requireBalanced {
            balancePartitions(in: &cube, statement: plan.statement, partition: ps)
        }

        return cube
    }
}


