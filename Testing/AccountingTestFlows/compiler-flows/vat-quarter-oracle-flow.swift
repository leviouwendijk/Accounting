import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var vatQuarterOracleFlow: TestFlow {
        TestFlow(
            "accounting-vat-quarter-oracle",
            tags: ["accounting", "vat", "filing", "conservation"]
        ) {
            Step("quarterly VAT comes from source postings and targeted corrections") {
                var calendar = Calendar(identifier: .iso8601)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
                    calendar.date(from: DateComponents(
                        year: year, month: month, day: day
                    ))!
                }
                func node(
                    _ id: Int, _ code: String,
                    _ direction: Direction, _ isBalance: Bool
                ) throws -> RGSNode {
                    try RGSNode(
                        id: id, codes: RGSNodeCodes(code: code),
                        labels: RGSNodeLabels(short: code, long: code),
                        direction: direction, level: 1,
                        temporality: isBalance ? .instant : .duration,
                        side: isBalance ? .balance : .profitLoss
                    )
                }
                let chart = try CompiledChart(
                    name: "VAT unit fixture", version: ChartVersion(major: 3, minor: 8),
                    nodes: [
                        try node(1, "BLimBanRba", .debit, true),
                        try node(2, "WOmzNodOdh", .credit, false),
                        try node(3, "WBedAlkOal", .debit, false),
                        try node(4, "BSchBepBtwOla", .credit, true),
                        try node(5, "BSchBepBtwVoo", .debit, true),
                    ]
                )
                let entity = try EntityKey(
                    class: "audit", family: "vat",
                    alias: try EntityAlias.parse("fixture")
                )
                let bank = try AccountKey("BLimBanRba")
                let turnover = try AccountKey("WOmzNodOdh")
                let expense = try AccountKey("WBedAlkOal")
                let output = try AccountKey("BSchBepBtwOla")
                let deductible = try AccountKey("BSchBepBtwVoo")
                func line(_ account: AccountKey, _ direction: Direction, _ amount: Int) -> ResolvedLine {
                    ResolvedLine(
                        entity: entity, account: account,
                        direction: direction, amount: Decimal(amount), adjustment: nil
                    )
                }
                func entry(
                    _ id: Int, _ date: Date, _ lines: [ResolvedLine],
                    _ vat: VATAnnotation? = nil
                ) -> ResolvedEntry {
                    ResolvedEntry(
                        id: id, date: .absolute(date), lines: lines,
                        details: nil, timezone: nil, metadata: [:],
                        transactionReferences: [], vat: vat
                    )
                }
                let q2 = VATPeriod(year: 2026, quarter: .q2)
                let entries: [ResolvedEntry] = [
                    entry(1, day(2026, 4, 15), [
                        line(bank, .debit, 1210),
                        line(turnover, .credit, 1000),
                        line(output, .credit, 210),
                    ]),
                    entry(2, day(2026, 5, 15), [
                        line(expense, .debit, 200),
                        line(deductible, .debit, 42),
                        line(bank, .credit, 242),
                    ]),
                    entry(3, day(2026, 7, 15), [
                        line(bank, .debit, 21),
                        line(output, .credit, 21),
                    ], VATAnnotation(kind: .correction, period: q2)),
                    entry(4, day(2026, 7, 20), [
                        line(bank, .debit, 33),
                        line(output, .credit, 33),
                    ]),
                ]
                for entry in entries { try entry.assertBalancing() }
                let report = try VATFilingBuilder.build(
                    resolvedEntries: entries, chart: chart,
                    window: PeriodWindow(
                        from: day(2026, 4, 1), to: day(2026, 6, 30).addingTimeInterval(86399)
                    ),
                    targetPeriod: q2, statusQuarter: nil,
                    balanceSheetNetPosition: nil, calendar: calendar
                )
                let totals = report.reconciliation
                try Expect.equal(totals.currentReturnRaw, Decimal(-189), "q2.source-vat-net")
                try Expect.equal(totals.currentPayable, Decimal(189), "q2.amount-payable")
                try Expect.equal(totals.currentReceivable, Decimal(0), "q2.amount-receivable")
                try Expect.equal(totals.unclassifiedDifference, Decimal(0), "q2.unclassified")
                try Expect.equal(
                    report.vatRows.filter { $0.family == .output }.reduce(into: Decimal(0)) { $0 += $1.rawVAT },
                    Decimal(-231), "q2.output-includes-earmarked-correction"
                )
                try Expect.equal(
                    report.vatRows.filter { $0.family == .deductible }.reduce(into: Decimal(0)) { $0 += $1.rawVAT },
                    Decimal(42), "q2.deductible"
                )
                try Expect.equal(
                    report.turnoverRows.reduce(into: Decimal(0)) { $0 += $1.amount },
                    Decimal(1000), "q2.turnover"
                )
            }
        }
    }
}
