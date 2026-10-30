import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var directAssemblerNetIncomeFlow: TestFlow {
        TestFlow(
            "accounting-direct-assembler-net-income",
            tags: ["accounting", "assembler", "net-income", "regression"]
        ) {
            Step("public assembler preserves signed P&L root and derived NI branch totals") {
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                let projectRoot = packageRoot.appendingPathComponent(
                    "Testing/accounting-example", isDirectory: true
                )
                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                let chart = try PeriodAssembler.buildChart(from: driver)
                guard
                    let bankID = chart.index?.byIdentifier["BLimBanRba"],
                    let rootID = chart.index?.byIdentifier["W"],
                    let niBranchID = chart.index?.byIdentifier["WNer"],
                    let niCategoryID = chart.index?.byIdentifier["WNerKap"],
                    let niID = chart.index?.byIdentifier["WNerKapKap"],
                    let equityID = chart.index?.byIdentifier["BEivKapOndAow"]
                else {
                    try Expect.true(false, "direct-assembler.required-chart-nodes")
                    return
                }

                let entity = try EntityKey(
                    class: "audit", family: "assembler",
                    alias: try EntityAlias.parse("direct")
                )
                let bank = try AccountKey("BLimBanRba")
                let revenue = try AccountKey("WOmzNodOdh")
                let ni = try AccountKey("WNerKapKap")
                let date = Date(timeIntervalSince1970: 0)
                let sale = ResolvedEntry(
                    id: 9951, date: .absolute(date),
                    lines: [
                        ResolvedLine(
                            entity: entity, account: bank,
                            direction: .debit, amount: 100, adjustment: nil
                        ),
                        ResolvedLine(
                            entity: entity, account: revenue,
                            direction: .credit, amount: 100, adjustment: nil
                        ),
                    ],
                    details: nil, timezone: nil, metadata: [:],
                    transactionReferences: []
                )
                let cut = AssembleCut(target: .L5)
                let saleRows = trialBalance([sale])
                let closed = try RGSAssembler.assemble(
                    chart: chart, trialRows: saleRows,
                    cut: cut, omslag: .ignore, autoClose: true
                )
                let unclosed = try RGSAssembler.assemble(
                    chart: chart, trialRows: saleRows,
                    cut: cut, omslag: .ignore, autoClose: false
                )

                func raw(_ bundle: StatementBundle, id: Int) -> Decimal? {
                    bundle.income.first(where: { $0.id == id })?.rawAmount
                }

                try Expect.equal(raw(closed, id: rootID), Decimal(-100), "direct.closed-root-once")
                try Expect.equal(raw(closed, id: niBranchID), Decimal(-100), "direct.closed-ni-branch")
                try Expect.equal(raw(closed, id: niCategoryID), Decimal(-100), "direct.closed-ni-category")
                try Expect.equal(raw(closed, id: niID), Decimal(-100), "direct.closed-derived-ni-leaf")
                try Expect.equal(closed.totalsById[bankID] ?? 0, Decimal(100), "direct.closed-bank")
                try Expect.equal(closed.totalsById[equityID] ?? 0, Decimal(-100), "direct.closed-equity")

                try Expect.equal(raw(unclosed, id: rootID), Decimal(-100), "direct.unclosed-root-once")
                try Expect.equal(raw(unclosed, id: niBranchID) ?? 0, Decimal(0), "direct.unclosed-no-derived-ni-branch")
                try Expect.equal(raw(unclosed, id: niCategoryID) ?? 0, Decimal(0), "direct.unclosed-no-derived-ni-category")
                try Expect.equal(raw(unclosed, id: niID) ?? 0, Decimal(0), "direct.unclosed-no-derived-ni")
                try Expect.equal(unclosed.totalsById[bankID] ?? 0, Decimal(100), "direct.unclosed-bank")
                try Expect.equal(unclosed.totalsById[equityID] ?? 0, Decimal(0), "direct.unclosed-no-equity-overlay")

                // A manually posted NI line suppresses the virtual close; the
                // authoritative income root then reflects ONLY real postings.
                let manual = ResolvedEntry(
                    id: 9952, date: .absolute(date),
                    lines: [
                        ResolvedLine(
                            entity: entity, account: ni,
                            direction: .debit, amount: 20, adjustment: nil
                        ),
                        ResolvedLine(
                            entity: entity, account: bank,
                            direction: .credit, amount: 20, adjustment: nil
                        ),
                    ],
                    details: nil, timezone: nil, metadata: [:],
                    transactionReferences: []
                )
                let manualClosed = try RGSAssembler.assemble(
                    chart: chart, trialRows: trialBalance([sale, manual]),
                    cut: cut, omslag: .ignore, autoClose: true
                )
                try Expect.equal(raw(manualClosed, id: rootID), Decimal(-80), "direct.manual-root-not-doubled")
                try Expect.equal(raw(manualClosed, id: niBranchID), Decimal(20), "direct.manual-ni-branch-preserved")
                try Expect.equal(raw(manualClosed, id: niCategoryID), Decimal(20), "direct.manual-ni-category-preserved")
                try Expect.equal(raw(manualClosed, id: niID), Decimal(20), "direct.manual-ni-preserved")
                try Expect.equal(manualClosed.totalsById[bankID] ?? 0, Decimal(80), "direct.manual-bank")
                try Expect.equal(manualClosed.totalsById[equityID] ?? 0, Decimal(0), "direct.manual-equity-not-virtually-closed")
            }
        }
    }
}
