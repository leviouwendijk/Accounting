import Foundation

public struct Aggregator: StatementAggregating {
    public let accounts: AccountStore
    public let plan: AggregationPlan
    public var onTrace: TraceHook? = nil   // was: ((String, StatementCube) -> Void)?

    public init(accounts: AccountStore, plan: AggregationPlan, onTrace: TraceHook? = nil) {
        self.accounts = accounts
        self.plan = plan
        self.onTrace = onTrace
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
        onTrace?("after_bucket_now", cube)

        if plan.includePreviousPeriods {
            bucket(postingsPrev, into: &cube, periodIndex: 1, matchers: matchers, partition: plan.partition)
            onTrace?("after_bucket_prev", cube)
        }

        // 5) Apply materiality per row (per period, and within partition groups)
        applyMateriality(in: &cube, statement: plan.statement, partition: plan.partition)
        onTrace?("after_materiality", cube)

        // 6) Optional: ensure partition-level balance for Balance Sheet views
        if plan.statement.kind == .balance, let ps = plan.partition, ps.requireBalanced {
            balancePartitions(in: &cube, statement: plan.statement, partition: ps)
            onTrace?("after_balance_partitions", cube)
        }
        return cube
    }
}
