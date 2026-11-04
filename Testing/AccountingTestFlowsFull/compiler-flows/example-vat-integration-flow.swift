import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var exampleVATIntegrationFlow: TestFlow {
        TestFlow("accounting-example-vat-integration", tags: ["accounting", "example", "vat"]) {
            Step("file-backed quarterly VAT and targeted correction") {
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent().deletingLastPathComponent()
                    .deletingLastPathComponent().deletingLastPathComponent()
                let projectRoot = packageRoot.appendingPathComponent("Testing/accounting-example", isDirectory: true)
                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                let chart = try PeriodAssembler.buildChart(from: driver)
                var cal = Calendar(identifier: .gregorian)
                cal.timeZone = TimeZone(identifier: "Europe/Amsterdam")!
                func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
                    cal.date(from: DateComponents(year: year, month: month, day: day))!
                }
                let q2 = VATPeriod(year: 2026, quarter: .q2)
                let q2Window = PeriodWindow(
                    from: day(2026, 4, 1),
                    to: day(2026, 7, 1).addingTimeInterval(-1)
                )
                let report = try VATFilingBuilder.build(
                    resolvedEntries: driver.resolved, chart: chart,
                    window: q2Window, targetPeriod: q2,
                    statusQuarter: nil, balanceSheetNetPosition: nil,
                    calendar: cal
                )
                try Expect.equal(report.reconciliation.currentReturnRaw, Decimal(-189), "example.q2-vat-net")
                try Expect.equal(report.reconciliation.currentPayable, Decimal(189), "example.q2-vat-payable")
                try Expect.equal(report.reconciliation.unclassifiedDifference, Decimal(0), "example.q2-vat-classification")
                try Expect.equal(
                    report.vatRows.filter { $0.family == .output }.reduce(into: Decimal(0)) { $0 += $1.rawVAT },
                    Decimal(-231), "example.q2-output-includes-july-correction"
                )
                try Expect.equal(
                    report.vatRows.filter { $0.family == .deductible }.reduce(into: Decimal(0)) { $0 += $1.rawVAT },
                    Decimal(42), "example.q2-input"
                )
                try Expect.equal(
                    report.turnoverRows.reduce(into: Decimal(0)) { $0 += $1.amount },
                    Decimal(1000), "example.q2-turnover"
                )

                // Reproduce the VAT overview and filing command projections
                // using the same explicit quarter and validated window route.
                let shape = PeriodShape(kind: .quarter)
                let anchor = day(2026, 6, 30)
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

                try Expect.equal(
                    windows.window.from,
                    q2Window.from,
                    "example.cli-q2-start"
                )
                try Expect.equal(
                    windows.window.to,
                    q2Window.to,
                    "example.cli-q2-end"
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

                let overview = try RGSAssembler.vatOverview(
                    "VAT integration overview",
                    bundle: native.bundle,
                    chart: native.chart,
                    includeCorrections: true,
                    minAbs: 0
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
                let legacyOverview = try RGSAssembler.vatOverview(
                    "VAT integration overview",
                    bundle: compatibility,
                    chart: native.chart,
                    includeCorrections: true,
                    minAbs: 0
                )

                try Expect.equal(
                    overview.netPosition,
                    legacyOverview.netPosition,
                    "example.cli-vat-overview-net-parity"
                )
                try Expect.equal(
                    overview.summaries.map { $0.amount },
                    legacyOverview.summaries.map { $0.amount },
                    "example.cli-vat-overview-summary-parity"
                )
                try Expect.equal(
                    overview.sections.flatMap { $0.rows }.map { $0.amount },
                    legacyOverview.sections.flatMap { $0.rows }.map { $0.amount },
                    "example.cli-vat-overview-row-parity"
                )

                // The standalone status command builds only a native chart.
                // Filing reuses the chart from the window output.
                let standaloneChart = try PeriodAssembler.buildChart(from: driver)
                let standaloneStatus = try VATStatusBuilder.build(
                    resolvedEntries: driver.resolved,
                    chart: standaloneChart,
                    title: "VAT standalone status",
                    period: windows.window,
                    tolerance: 0,
                    calendar: cal,
                    businessEntity: .vof
                )
                let filingStatus = try VATStatusBuilder.build(
                    resolvedEntries: driver.resolved,
                    chart: native.chart,
                    title: "VAT filing status",
                    period: windows.window,
                    tolerance: 0,
                    calendar: cal,
                    businessEntity: .vof
                )

                try Expect.equal(
                    standaloneStatus.quarters.map { $0.period },
                    filingStatus.quarters.map { $0.period },
                    "example.cli-vat-status-quarter-parity"
                )
                try Expect.equal(
                    standaloneStatus.quarters.map { $0.residual },
                    filingStatus.quarters.map { $0.residual },
                    "example.cli-vat-status-residual-parity"
                )

                guard let statusQuarter = filingStatus.quarters.first(where: {
                    $0.period == q2
                }) else {
                    try Expect.true(false, "example.cli-vat-filing-q2-status-present")
                    return
                }

                let filing = try VATFilingBuilder.build(
                    resolvedEntries: driver.resolved,
                    chart: native.chart,
                    window: windows.window,
                    targetPeriod: q2,
                    statusQuarter: statusQuarter,
                    balanceSheetNetPosition: overview.netPosition,
                    title: "VAT integration filing",
                    calendar: cal,
                    businessEntity: .vof
                )

                try Expect.equal(
                    filing.reconciliation.currentReturnRaw,
                    Decimal(-189),
                    "example.cli-vat-filing-current-return"
                )
                try Expect.equal(
                    filing.reconciliation.currentReturnRaw,
                    report.reconciliation.currentReturnRaw,
                    "example.cli-vat-filing-source-parity"
                )
                try Expect.equal(
                    filing.reconciliation.unclassifiedDifference,
                    Decimal(0),
                    "example.cli-vat-filing-classification"
                )
                try Expect.equal(
                    filing.reconciliation.balanceSheetNetPosition,
                    overview.netPosition,
                    "example.cli-vat-filing-balance-input"
                )
            }
        }
    }
}
