import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var nativeResolvedOutputIntegrationFlow: TestFlow {
        TestFlow(
            "accounting-native-resolved-output-integration",
            tags: ["accounting", "native", "resolved", "integration"]
        ) {
            Step("complete RGS example validates and retains source postings") {
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()

                let projectRoot = packageRoot.appendingPathComponent(
                    "Testing/accounting-example",
                    isDirectory: true
                )

                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                let chart = try PeriodAssembler.buildChart(from: driver)

                let sourceAccounts = Set(
                    driver.resolved.flatMap { entry in
                        entry.lines.map { $0.account.code }
                    }
                )
                let chartAccounts = Set(chart.nodes.map { $0.codes.code })
                let missingAccounts = sourceAccounts.subtracting(chartAccounts).sorted()

                try Expect.equal(
                    missingAccounts,
                    [String](),
                    "all file-backed posting accounts must exist in the RGS chart"
                )

                let hierarchy = RGSIdentifierHierarchy.build(from: chart.nodes)
                let ambiguous = hierarchy.problems.compactMap { problem -> String? in
                    if case .multipleParents = problem.kind {
                        return problem.childCode
                    }
                    return nil
                }.sorted()

                try Expect.equal(
                    ambiguous.count,
                    0,
                    "validated full chart must not choose ambiguous parents; first candidates: \(Array(ambiguous.prefix(10)))"
                )

                let cut = AssembleCut(target: .L3)
                let native = try NativeOutputBuilder.buildResolvedCompileOutput(
                    result: driver,
                    cut: cut,
                    omslag: .ignore,
                    autoClose: false
                )

                let movements = native.movements
                let expectedPostingCount = driver.resolved.reduce(0) {
                    $0 + $1.lines.count
                }

                try Expect.true(
                    expectedPostingCount > 0,
                    "example project must contain resolved postings"
                )
                try Expect.equal(
                    movements.batch.entries.count,
                    driver.resolved.count,
                    "every resolved entry remains available"
                )
                try Expect.equal(
                    movements.batch.postings.count,
                    expectedPostingCount,
                    "every resolved source line becomes exactly one posting"
                )

                let sourceTotal = movements.batch.postings.reduce(Decimal(0)) {
                    $0 + $1.amount
                }
                try Expect.equal(
                    sourceTotal,
                    Decimal(0),
                    "complete source postings preserve the double-entry equation"
                )

                var recombinedById: [Int: Decimal] = [:]
                for (key, amount) in movements.sourceSeedAEById {
                    recombinedById[key.accountId, default: 0] += amount
                }
                try Expect.equal(
                    recombinedById,
                    movements.sourceSeedById,
                    "entity-specific source seeds reconstruct direct account seeds exactly"
                )

                if let first = movements.batch.postings.first {
                    guard let entry = movements.entry(for: first.origin),
                          let line = movements.line(for: first.origin) else {
                        try Expect.true(false, "first source posting must resolve to its original entry and line")
                        return
                    }
                    try Expect.equal(
                        first.account.key,
                        line.account,
                        "first posting retains original RGS classification"
                    )
                    try Expect.equal(
                        entry.id,
                        driver.resolved[first.origin.entryIndex].id,
                        "first posting retains original entry identity"
                    )
                }

                if let last = movements.batch.postings.last {
                    guard let line = movements.line(for: last.origin) else {
                        try Expect.true(false, "last source posting must resolve to its original line")
                        return
                    }
                    try Expect.equal(
                        last.account.key,
                        line.account,
                        "last posting retains original classification"
                    )
                    try Expect.equal(
                        last.origin.entryIndex,
                        driver.resolved.count - 1,
                        "last source posting retains its entry position"
                    )
                }

                // Independent trial-balance regression oracle. Do not
                // obtain this through the validated compatibility adapter.
                let legacy = NativeCompileOutput(
                    result: driver,
                    chart: chart,
                    bundle: try RGSAssembler.assemble(
                        chart: chart,
                        trialRows: trialBalance(driver.resolved),
                        cut: cut,
                        omslag: .ignore,
                        for: .vof,
                        autoClose: false
                    )
                )

                try Expect.equal(
                    native.bundle.totalsById,
                    legacy.bundle.totalsById,
                    "complete RGS direct source totals match legacy output"
                )
                try Expect.equal(
                    native.bundle.balance.map(\.id),
                    legacy.bundle.balance.map(\.id),
                    "complete RGS balance presentation identities match"
                )
                try Expect.equal(
                    native.bundle.balance.map(\.rawAmount),
                    legacy.bundle.balance.map(\.rawAmount),
                    "complete RGS balance raw amounts match"
                )
                try Expect.equal(
                    native.bundle.income.map(\.id),
                    legacy.bundle.income.map(\.id),
                    "complete RGS income presentation identities match"
                )
                try Expect.equal(
                    native.bundle.income.map(\.rawAmount),
                    legacy.bundle.income.map(\.rawAmount),
                    "complete RGS income raw amounts match"
                )

                try Expect.equal(
                    native.output.bundle.totalsById,
                    native.bundle.totalsById,
                    "native compatibility projection preserves validated totals"
                )
            }

            Step("complete RGS auto-close preserves legacy statements") {
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()

                let projectRoot = packageRoot.appendingPathComponent(
                    "Testing/accounting-example",
                    isDirectory: true
                )

                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                let cut = AssembleCut(target: .L3)

                let legacyChart = try PeriodAssembler.buildChart(from: driver)
                let legacy = NativeCompileOutput(
                    result: driver,
                    chart: legacyChart,
                    bundle: try RGSAssembler.assemble(
                        chart: legacyChart,
                        trialRows: trialBalance(driver.resolved),
                        cut: cut,
                        omslag: .ignore,
                        for: .vof,
                        autoClose: true
                    )
                )
                let validated = try NativeOutputBuilder.buildResolvedCompileOutput(
                    result: driver,
                    cut: cut,
                    omslag: .ignore,
                    autoClose: true
                )

                // An independent DEALER projection of source postings
                // and the assembled, auto-closed balance-sheet position.
                let mapping = try RGSCategoryMapping.standard(
                    chart: validated.chart
                )
                let classifiedChart = try RGSChartProvider(
                    categoryMapping: mapping
                ).compile(validated.chart)

                try Expect.equal(
                    classifiedChart.category(of: try AccountKey("BLimBanRba")),
                    AccountCategory.assets,
                    "bank inherits assets from the RGS family"
                )
                try Expect.equal(
                    classifiedChart.category(of: try AccountKey("BSchBepBtwOla")),
                    AccountCategory.liabilities,
                    "VAT payable inherits liabilities"
                )
                try Expect.equal(
                    classifiedChart.category(of: try AccountKey("WOmzNodOdh")),
                    AccountCategory.revenue,
                    "service revenue inherits its economic category"
                )

                let categorized = try CategorizedAccountingResult(
                    output: validated,
                    mapping: mapping
                )
                try categorized.assertIdentities()

                try Expect.equal(categorized.source(.assets), Decimal(4947), "DEALER.source-assets")
                try Expect.equal(categorized.source(.liabilities), Decimal(222), "DEALER.source-liabilities")
                try Expect.equal(categorized.source(.equity), Decimal(1000), "DEALER.source-equity")
                try Expect.equal(categorized.source(.revenue), Decimal(4150), "DEALER.source-revenue")
                try Expect.equal(categorized.source(.expenses), Decimal(425), "DEALER.source-expenses")
                try Expect.equal(categorized.source(.dividends), Decimal(0), "DEALER.source-distributions")
                try Expect.equal(categorized.sourceIdentityDelta, Decimal(0), "DEALER.open-identity")

                try Expect.equal(categorized.closing(.assets), Decimal(4947), "DEALER.closing-assets")
                try Expect.equal(categorized.closing(.liabilities), Decimal(222), "DEALER.closing-liabilities")
                try Expect.equal(categorized.closing(.equity), Decimal(4725), "DEALER.closing-equity")
                try Expect.equal(categorized.closingIdentityDelta, Decimal(0), "DEALER.closing-identity")

                if validated.chart.index?.byIdentifier["BEivKapPro"] != nil {
                    try Expect.equal(
                        mapping.category(for: "BEivKapPro"),
                        AccountCategory.dividends,
                        "owner withdrawals are semantically distributions"
                    )
                }

                // Partial mapping must not silently omit active accounts.
                let incomplete = try RGSCategoryMapping(
                    chart: validated.chart,
                    families: ["BLim": .assets]
                )
                do {
                    _ = try CategorizedAccountingResult(
                        output: validated,
                        mapping: incomplete
                    )
                    try Expect.true(false, "incomplete classification must fail")
                } catch let error as CategorizedAccountingError {
                    switch error {
                    case .unclassifiedSourceAccount, .unclassifiedBalanceFamily:
                        break
                    default:
                        try Expect.true(false, "unexpected incomplete-mapping error: \(error)")
                    }
                }

                // A balanced pair on one otherwise unmapped account must be
                // rejected even though its net source seed is exactly zero.
                guard let exampleEntry = driver.resolved.first,
                      let exampleEntity = exampleEntry.lines.first?.entity else {
                    try Expect.true(false, "source entity required for synthetic postings")
                    return
                }

                let revenueAccount = try AccountKey("WOmzNodOdh")
                let cancellingEntry = ResolvedEntry(
                    id: nil,
                    date: exampleEntry.date,
                    lines: [
                        ResolvedLine(
                            entity: exampleEntity,
                            account: revenueAccount,
                            direction: .debit,
                            amount: Decimal(100),
                            adjustment: nil
                        ),
                        ResolvedLine(
                            entity: exampleEntity,
                            account: revenueAccount,
                            direction: .credit,
                            amount: Decimal(100),
                            adjustment: nil
                        )
                    ],
                    details: "Cancellation coverage validation",
                    timezone: nil,
                    metadata: [:],
                    transactionReferences: []
                )
                let cancellingBatch = try classifiedChart.postings(from: [cancellingEntry])
                try Expect.equal(
                    cancellingBatch.postings.count,
                    2,
                    "cancelling source lines remain separate postings"
                )
                try Expect.equal(
                    cancellingBatch.postings.reduce(Decimal(0)) { $0 + $1.amount },
                    Decimal(0),
                    "unmapped account has zero net movement"
                )
                // Synthetic resolved compilation containing only the
                // cancelling postings, so zero-net coverage is tested.
                let cancellingResult = EntryCompileDriver.Result(
                    entities: driver.entities,
                    accounts: driver.accounts,
                    transactions: driver.transactions,
                    entries: [],
                    resolved: [cancellingEntry]
                )
                let cancellingAssembly = try RGSAssembler.assembleResolved(
                    chart: validated.chart,
                    entries: cancellingResult.resolved,
                    cut: cut,
                    omslag: .ignore,
                    for: .vof,
                    autoClose: true,
                    entityId: { driver.entities.idIndex[$0] }
                )
                let cancellingOutput = NativeResolvedCompileOutput(
                    result: cancellingResult,
                    chart: validated.chart,
                    assembly: cancellingAssembly
                )
                var missingRevenueFamilies = mapping.families
                missingRevenueFamilies.removeValue(forKey: "WOmz")
                let missingRevenueMapping = try RGSCategoryMapping(
                    chart: validated.chart,
                    families: missingRevenueFamilies
                )
                do {
                    _ = try CategorizedAccountingResult(
                        output: cancellingOutput,
                        mapping: missingRevenueMapping
                    )
                    try Expect.true(false, "zero-net unmapped postings must be rejected")
                } catch let error as CategorizedAccountingError {
                    try Expect.equal(
                        error,
                        .unclassifiedSourceAccount(revenueAccount.code),
                        "category coverage is checked before net aggregation"
                    )
                }

                // RGS statement sides prohibit category-family mismatches.
                var incompatibleFamilies = mapping.families
                incompatibleFamilies["WOmz"] = .assets
                do {
                    _ = try RGSCategoryMapping(
                        chart: validated.chart,
                        families: incompatibleFamilies
                    )
                    try Expect.true(false, "income family cannot be classified as assets")
                } catch let error as RGSCategoryMappingError {
                    try Expect.equal(
                        error,
                        .incompatibleStatementSide(code: "WOmz", category: .assets),
                        "cross-statement classification rejected"
                    )
                }

                // An inconsistent closing position must be detected even
                // when source postings remain perfectly balanced.
                guard let bankFamilyID = validated.chart.index?.byIdentifier["BLim"] else {
                    try Expect.true(false, "bank family required for imbalance test")
                    return
                }
                var corruptedTotals = validated.bundle.totalsById
                corruptedTotals[bankFamilyID, default: 0] += 1
                let corruptedBundle = StatementBundle(
                    balance: validated.bundle.balance,
                    income: validated.bundle.income,
                    totalsById: corruptedTotals
                )
                // Deliberately construct an invalid assembly for the
                // negative identity test; production uses the assembler.
                let corruptedOutput = NativeResolvedCompileOutput(
                    result: driver,
                    chart: validated.chart,
                    assembly: RGSResolvedAssembly(
                        statements: corruptedBundle,
                        movements: validated.movements
                    )
                )
                let corrupted = try CategorizedAccountingResult(
                    output: corruptedOutput,
                    mapping: mapping
                )
                try Expect.equal(corrupted.sourceIdentityDelta, Decimal(0), "source-remains-balanced")
                try Expect.equal(corrupted.closingIdentityDelta, Decimal(1), "closing-imbalance-detected")
                do {
                    try corrupted.assertIdentities()
                    try Expect.true(false, "corrupted closing position must fail")
                } catch let error as CategorizedAccountingError {
                    try Expect.equal(
                        error,
                        .closingIdentityMismatch(Decimal(1)),
                        "typed closing-identity failure"
                    )
                }

                // A VOF private capital withdrawal is a source distribution,
                // while its bank credit reduces assets and closing equity.
                let drawingsAccount = try AccountKey("BEivKapProPok")
                let bankAccount = try AccountKey("BLimBanRba")
                let withdrawalEntry = ResolvedEntry(
                    id: nil,
                    date: exampleEntry.date,
                    lines: [
                        ResolvedLine(
                            entity: exampleEntity,
                            account: drawingsAccount,
                            direction: .debit,
                            amount: Decimal(125),
                            adjustment: nil
                        ),
                        ResolvedLine(
                            entity: exampleEntity,
                            account: bankAccount,
                            direction: .credit,
                            amount: Decimal(125),
                            adjustment: nil
                        )
                    ],
                    details: "Synthetic VOF owner's private withdrawal",
                    timezone: nil,
                    metadata: [:],
                    transactionReferences: []
                )
                try withdrawalEntry.assertBalancing()
                let withdrawalAssembly = try RGSAssembler.assembleResolved(
                    chart: validated.chart,
                    entries: driver.resolved + [withdrawalEntry],
                    cut: cut,
                    omslag: .ignore,
                    for: .vof,
                    autoClose: true,
                    entityId: { driver.entities.idIndex[$0] }
                )
                let withdrawnResult = EntryCompileDriver.Result(
                    entities: driver.entities,
                    accounts: driver.accounts,
                    transactions: driver.transactions,
                    entries: driver.entries,
                    resolved: driver.resolved + [withdrawalEntry]
                )
                let withdrawnOutput = NativeResolvedCompileOutput(
                    result: withdrawnResult,
                    chart: validated.chart,
                    assembly: withdrawalAssembly
                )
                let withdrawn = try CategorizedAccountingResult(
                    output: withdrawnOutput,
                    mapping: mapping
                )
                try withdrawn.assertIdentities()
                try Expect.equal(
                    mapping.category(for: drawingsAccount.code),
                    AccountCategory.dividends,
                    "private capital withdrawal inherits distribution category"
                )
                try Expect.equal(withdrawn.source(.dividends), Decimal(125), "drawings.source-distributions")
                try Expect.equal(withdrawn.source(.assets), Decimal(4822), "drawings.source-assets")
                try Expect.equal(withdrawn.source(.equity), Decimal(1000), "drawings.source-equity")
                try Expect.equal(withdrawn.source(.revenue), Decimal(4150), "drawings.source-revenue")
                try Expect.equal(withdrawn.source(.expenses), Decimal(425), "drawings.source-expenses")
                try Expect.equal(withdrawn.closing(.assets), Decimal(4822), "drawings.closing-assets")
                try Expect.equal(withdrawn.closing(.liabilities), Decimal(222), "drawings.closing-liabilities")
                try Expect.equal(withdrawn.closing(.equity), Decimal(4600), "drawings.closing-equity")
                try Expect.equal(withdrawn.sourceIdentityDelta, Decimal(0), "drawings.source-identity")
                try Expect.equal(withdrawn.closingIdentityDelta, Decimal(0), "drawings.closing-identity")

                try Expect.equal(
                    validated.bundle.totalsById,
                    legacy.bundle.totalsById,
                    "full-chart auto-close totals match legacy output"
                )
                try Expect.equal(
                    validated.bundle.balance.map(\.id),
                    legacy.bundle.balance.map(\.id),
                    "auto-close balance identities match"
                )
                try Expect.equal(
                    validated.bundle.balance.map(\.rawAmount),
                    legacy.bundle.balance.map(\.rawAmount),
                    "auto-close balance raw amounts match"
                )
                try Expect.equal(
                    validated.bundle.income.map(\.id),
                    legacy.bundle.income.map(\.id),
                    "auto-close income identities match"
                )
                try Expect.equal(
                    validated.bundle.income.map(\.rawAmount),
                    legacy.bundle.income.map(\.rawAmount),
                    "auto-close income raw amounts match"
                )

                try Expect.equal(
                    validated.movements.sourceSeedById,
                    RGSAssembler.seedLeafs(
                        from: trialBalance(driver.resolved),
                        using: validated.chart.index!
                    ),
                    "source seeds match the legacy trial balance before auto-close"
                )
                try Expect.equal(
                    validated.movements.batch.entries.count,
                    driver.resolved.count,
                    "auto-close does not replace source entries with synthetic postings"
                )
                try Expect.equal(
                    validated.movements.batch.postings.count,
                    driver.resolved.reduce(0) { $0 + $1.lines.count },
                    "auto-close does not introduce synthetic source postings"
                )
            }
        }
    }
}
