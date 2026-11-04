import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var exampleDepreciationIntegrationFlow: TestFlow {
        TestFlow("accounting-example-depreciation-integration", tags: ["accounting", "example", "depreciation"]) {
            Step("missing April depreciation is projected independently of writer") {
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent().deletingLastPathComponent()
                    .deletingLastPathComponent().deletingLastPathComponent()
                let projectRoot = packageRoot.appendingPathComponent("Testing/accounting-example", isDirectory: true)
                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                // Distinguish missing/ignored asset configuration from a missing slice.
                let configured = try DepreciationResolutionPass.run(
                    on: driver.entities,
                    using: driver.accounts
                )
                try Expect.equal(configured.depreciationMap.count, 1, "example.one-resolved-asset")
                var cal = Calendar(identifier: .gregorian)
                cal.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
                let may1 = cal.date(from: DateComponents(year: 2026, month: 5, day: 1))!
                let report = try DepreciationAuditRunner.run(
                    entities: driver.entities, accounts: driver.accounts,
                    resolvedEntries: driver.resolved,
                    through: may1.addingTimeInterval(-1),
                    options: .init(granularity: .monthly, tolerance: 0, calendar: cal)
                )
                let april = report.items.filter {
                    let c = cal.dateComponents([.year, .month], from: $0.periodStart)
                    return c.year == 2026 && c.month == 4
                }
                try Expect.equal(april.count, 1, "example.asset-april-slice-count")
                try Expect.equal(
                    april.reduce(into: Decimal(0)) { $0 += $1.expected },
                    Decimal(20), "example.asset-april-expected"
                )
                try Expect.equal(
                    april.reduce(into: Decimal(0)) { $0 += $1.actual },
                    Decimal(0), "example.asset-april-unposted"
                )
                try Expect.equal(
                    april.reduce(into: Decimal(0)) { $0 += $1.delta },
                    Decimal(-20), "example.asset-april-missing-amount"
                )

                // Mid-month commissioning must NOT pull a partial April into
                // the firstFullMonth convention; the first slice is May.
                guard let asset = configured.depreciationMap.values.first else {
                    try Expect.true(false, "example.asset-depreciation-config-present")
                    return
                }
                let april15 = cal.date(from: DateComponents(year: 2026, month: 4, day: 15))!
                let june1 = cal.date(from: DateComponents(year: 2026, month: 6, day: 1))!
                let midMonth = asset.project(
                    through: june1.addingTimeInterval(-1),
                    startDate: april15,
                    startConvention: .firstFullMonth,
                    granularity: .monthly,
                    calendar: cal
                )
                try Expect.equal(midMonth.count, 1, "example.mid-month-one-full-month")
                try Expect.equal(midMonth.first?.periodStart, may1, "example.mid-month-starts-in-may")
                try Expect.equal(midMonth.first?.depreciation, Decimal(20), "example.mid-month-may-amount")

                // Exercise the assets overview CLI's native reconciliation
                // against an independent trial-balance compatibility bundle.
                let shape = PeriodShape(kind: .quarter)
                let anchor = cal.date(from: DateComponents(
                    year: 2026,
                    month: 6,
                    day: 30
                ))!
                let windows = PeriodSlicer.resolve(
                    shape: shape,
                    anchor: anchor,
                    calendar: cal
                )
                let cut = AssembleCut(
                    target: .L3,
                    includeCodes: [],
                    includeIntermediates: true,
                    omitZerosBeyondLevel1: true
                )

                let overview = try AssetViews.AssetsOverviewBuilder.build(
                    result: driver,
                    period: windows.window,
                    calendar: cal
                )
                try Expect.true(
                    !overview.groups.isEmpty,
                    "example.cli-assets-source-groups-present"
                )

                let native = try NativeOutputBuilder.buildWindowOutput(
                    result: driver,
                    windows: windows,
                    anchor: anchor,
                    shape: shape,
                    cut: cut,
                    omslag: .apply,
                    entity: .vof,
                    calendar: cal
                )
                let reconciliation = AssetViews.AssetFilingReconciliationBuilder.build(
                    overview: overview,
                    chart: native.chart,
                    bundle: native.bundle,
                    tolerance: 0
                )

                let compatibility = try PeriodAssembler.buildCurrentBundle(
                    chart: native.chart,
                    wins: windows,
                    anchor: anchor,
                    result: driver,
                    cut: cut,
                    omslag: .apply,
                    entity: .vof,
                    shape: shape,
                    calendar: cal
                )
                let legacyReconciliation = AssetViews.AssetFilingReconciliationBuilder.build(
                    overview: overview,
                    chart: native.chart,
                    bundle: compatibility,
                    tolerance: 0
                )

                try Expect.equal(
                    reconciliation.checkCount,
                    6,
                    "example.cli-assets-six-reconciliation-metrics"
                )
                try Expect.equal(
                    reconciliation.rows.map { $0.ledger },
                    legacyReconciliation.rows.map { $0.ledger },
                    "example.cli-assets-ledger-parity"
                )
                try Expect.equal(
                    reconciliation.rows.map { $0.difference },
                    legacyReconciliation.rows.map { $0.difference },
                    "example.cli-assets-difference-parity"
                )
                try Expect.equal(
                    reconciliation.failureCount,
                    legacyReconciliation.failureCount,
                    "example.cli-assets-failure-count-parity"
                )

                for row in reconciliation.rows {
                    try Expect.equal(
                        row.passed,
                        row.difference == 0,
                        "example.cli-assets-zero-tolerance-decision"
                    )
                }
            }
        }
    }
}
