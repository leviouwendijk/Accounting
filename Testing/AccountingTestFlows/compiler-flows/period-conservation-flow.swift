import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var periodConservationFlow: TestFlow {
        TestFlow(
            "accounting-period-conservation",
            tags: ["accounting", "period", "conservation"]
        ) {
            Step("opening plus window movements equals cumulative through cutoff") {
                var calendar = Calendar(identifier: .iso8601)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!

                func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
                    calendar.date(from: DateComponents(
                        year: year, month: month, day: day
                    ))!
                }

                let entity = try EntityKey(
                    class: "audit", family: "period",
                    alias: try EntityAlias.parse("fixture")
                )
                let bank = try AccountKey("BLimBanRba")
                let offset = try AccountKey("WOmzNodOdh")
                let events: [(Int, Date, Int)] = [
                    (9801, day(2025, 12, 15), 1000),
                    (9802, day(2025, 12, 22), 300),
                    (9803, day(2026, 1, 10), 200),
                    (9804, day(2026, 1, 11), -50),
                    (9805, day(2026, 3, 15), 400),
                    (9806, day(2026, 7, 10), 600),
                    (9807, day(2026, 7, 11), -100),
                    (9808, day(2026, 8, 5), 250),
                    (9809, day(2026, 8, 12), -75),
                    (9810, day(2026, 8, 25), 500),
                    (9811, day(2026, 9, 10), 900),
                ]

                let entries: [ResolvedEntry] = events.map { event in
                    let (id, date, change) = event
                    let amount = Decimal(Swift.abs(change))
                    return ResolvedEntry(
                        id: id, date: .absolute(date),
                        lines: [
                            ResolvedLine(
                                entity: entity, account: bank,
                                direction: change >= 0 ? .debit : .credit,
                                amount: amount, adjustment: nil
                            ),
                            ResolvedLine(
                                entity: entity, account: offset,
                                direction: change >= 0 ? .credit : .debit,
                                amount: amount, adjustment: nil
                            ),
                        ],
                        details: nil, timezone: nil, metadata: [:],
                        transactionReferences: []
                    )
                }

                func bankTotal(_ source: [ResolvedEntry]) -> Decimal {
                    source.reduce(into: Decimal(0)) { total, entry in
                        for line in entry.lines where line.account == bank {
                            total += line.direction == .debit ? line.amount : -line.amount
                        }
                    }
                }

                let anchor = day(2026, 8, 15)
                let cases: [(String, PeriodShape, Int, Int, Int)] = [
                    ("august-to-date", .init(kind: .month, rangeToDate: true), 2350, 175, 2525),
                    ("august", .init(kind: .month), 2350, 675, 3025),
                    ("year-to-date", .init(kind: .year, rangeToDate: true), 1300, 1225, 2525),
                    ("year", .init(kind: .year), 1300, 2625, 3925),
                    ("lifetime", .init(kind: .lifetime), 0, 3925, 3925),
                ]

                for (name, shape, expectedOpening, expectedMovement, expectedClosing) in cases {
                    let windows = PeriodSlicer.resolve(
                        shape: shape, anchor: anchor, calendar: calendar
                    )
                    let parts = PeriodAssembler.entriesForWindows(entries, windows)
                    let historicalIDs = Set(parts.historical.compactMap(\.id))
                    let movementIDs = Set(parts.window.compactMap(\.id))

                    try Expect.equal(
                        historicalIDs.intersection(movementIDs).count, 0,
                        "\(name).no-overlap"
                    )
                    try Expect.equal(bankTotal(parts.historical), Decimal(expectedOpening), "\(name).opening")
                    try Expect.equal(bankTotal(parts.window), Decimal(expectedMovement), "\(name).movement")
                    try Expect.equal(bankTotal(parts.ytd), Decimal(expectedClosing), "\(name).cumulative")
                    try Expect.equal(
                        bankTotal(parts.historical) + bankTotal(parts.window),
                        bankTotal(parts.ytd), "\(name).conservation"
                    )
                }
            }

            Step("full compiler preserves bank positions and P&L parent totals") {
                var calendar = Calendar(identifier: .iso8601)
                calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let anchor = calendar.date(from: DateComponents(
                    year: 2026, month: 8, day: 15
                ))!
                let packageRoot = URL(fileURLWithPath: #filePath)
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                    .deletingLastPathComponent()
                // Assemble the immutable posting oracle in a temporary project.
                // Reuse only the sample's RGS/settings; future example postings do
                // not enter this regression fixture.
                let exampleRoot = packageRoot.appendingPathComponent(
                    "Testing/accounting-example", isDirectory: true
                )
                let fixtureRoot = packageRoot.appendingPathComponent(
                    "Testing/fixtures/period-conservation", isDirectory: true
                )
                let fm = FileManager.default
                let projectRoot = fm.temporaryDirectory.appendingPathComponent(
                    "accounting-period-\(UUID().uuidString)", isDirectory: true
                )
                try fm.createDirectory(at: projectRoot, withIntermediateDirectories: true)
                defer { try? fm.removeItem(at: projectRoot) }
                for (source, directory) in [
                    (exampleRoot, "config"),
                    (fixtureRoot, "entries"),
                    (fixtureRoot, "transactions"),
                ] {
                    try fm.copyItem(
                        at: source.appendingPathComponent(directory, isDirectory: true),
                        to: projectRoot.appendingPathComponent(directory, isDirectory: true)
                    )
                }
                let driver = try EntryCompileDriver.compile(
                    project: EntryCompilerProject(root: projectRoot),
                    setting: CompileDriveSetting(loc_trace: false)
                )
                let chart = try PeriodAssembler.buildChart(from: driver)
                guard
                    let bankID = chart.index?.byIdentifier["BLimBanRba"],
                    let incomeRootID = chart.index?.byIdentifier["W"],
                    let niBranchID = chart.index?.byIdentifier["WNer"],
                    let niCategoryID = chart.index?.byIdentifier["WNerKap"],
                    let niLeafID = chart.index?.byIdentifier["WNerKapKap"]
                else {
                    try Expect.true(false, "fixture RGS bank and P&L root nodes must exist")
                    return
                }
                let cases: [(String, PeriodShape, Int, Int)] = [
                    ("august-to-date", .init(kind: .month, rangeToDate: true), 2525, 175),
                    ("august", .init(kind: .month), 3025, 675),
                    ("year-to-date", .init(kind: .year, rangeToDate: true), 2525, 1225),
                    ("year", .init(kind: .year), 3925, 2625),
                    ("lifetime", .init(kind: .lifetime), 3925, 2925),
                ]
                for (name, shape, expectedBank, expectedProfit) in cases {
                    let report = try PeriodAssembler.assemble(
                        shape: shape, anchor: anchor, result: driver,
                        calendar: calendar
                    )
                    let actualBank = report.current.bundle.totalsById[bankID] ?? 0
                    try Expect.equal(
                        actualBank, Decimal(expectedBank), "\(name).compiled-bank"
                    )
                    // The rendered line level comes from the sorting-key depth,
                    // which is not necessarily the account's RGS hierarchy depth.
                    // Identify the single authoritative P&L root by its chart ID.
                    guard let root = report.current.bundle.income.first(where: {
                        $0.id == incomeRootID
                    }) else {
                        try Expect.true(false, "\(name).income-root-present")
                        continue
                    }
                    // Raw accounting signs are debit-minus-credit: profit is negative.
                    try Expect.equal(
                        root.rawAmount, -Decimal(expectedProfit),
                        "\(name).income-root-signed-and-not-doubled"
                    )
                    for (label, id) in [
                        ("ni-branch", niBranchID),
                        ("ni-category", niCategoryID),
                        ("ni-leaf", niLeafID),
                    ] {
                        guard let line = report.current.bundle.income.first(where: {
                            $0.id == id
                        }) else {
                            try Expect.true(false, "\(name).\(label)-present")
                            continue
                        }
                        try Expect.equal(
                            line.rawAmount, -Decimal(expectedProfit),
                            "\(name).\(label)-matches-income-root"
                        )
                    }
                }
            }
        }
    }
}
