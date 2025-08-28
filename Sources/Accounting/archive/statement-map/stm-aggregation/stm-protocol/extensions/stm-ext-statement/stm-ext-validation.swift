import Foundation

public extension StatementAggregating {
    func validateCoverage(
        entries: [ResolvedEntry],
        accounts: AccountStore,
        statement: StatementDef,
        filters: [DimensionFilter] = []
    ) throws {
        let matchers = try compileMatchers(for: statement)        // existing helper
        var issues: [CoverageIssue] = []

        for e in entries {
            for ln in e.lines {
                let p = try normalize(e, ln, accounts: accounts)  // existing normalize
                guard evaluateFilters(filters, on: p.dims) else { continue }  // existing filter

                // hit any rule?
                var matched = false
                for m in matchers {
                    if m.predicate(p) { matched = true; break }
                }
                if !matched {
                    issues.append(.init(
                        accountCode: ln.account.code,
                        rgs: p.rgsCode,
                        omslag: p.omslag,
                        amount: p.amount,
                        dims: p.dims
                    ))
                }
            }
        }

        if !issues.isEmpty {
            // your call: throw or print nicely and then throw
            // throw AggregationError.unmapped(issues)
            FileHandle.standardError.write(Data(("[Aggregation] Unmapped postings detected: \(issues.count)\n").utf8))
            for i in issues.prefix(20) {
                FileHandle.standardError.write(Data( "  • \(i.accountCode) rgs=\(i.rgs) omslag=\(i.omslag ?? "-") amt=\(i.amount)\n".utf8))
            }
            // If strict:
            // throw AggregationError.unmapped(issues)
        }
    }
}
