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
            }
        }
    }
}
