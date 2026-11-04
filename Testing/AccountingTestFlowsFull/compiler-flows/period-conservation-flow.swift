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
                    let selection = PeriodEntrySelection(
                        sourceEntries: entries,
                        windows: windows,
                        calendar: calendar
                    )

                    try Expect.equal(
                        selection.sourceEntries,
                        entries,
                        "\(name).original-resolved-entries-retained"
                    )
                    try Expect.equal(
                        selection.entries(at: selection.historicalOffsets),
                        parts.historical,
                        "\(name).historical-selection-parity"
                    )
                    try Expect.equal(
                        selection.entries(at: selection.windowOffsets),
                        parts.window,
                        "\(name).window-selection-parity"
                    )
                    try Expect.equal(
                        selection.entries(at: selection.ytdOffsets),
                        parts.ytd,
                        "\(name).cumulative-selection-parity"
                    )
                    try Expect.equal(
                        selection.windowOffsets.map { entries[$0].id },
                        parts.window.map(\.id),
                        "\(name).source-offsets-preserve-entry-order"
                    )
                    try Expect.equal(
                        selection.unresolvedDateOffsets,
                        [Int](),
                        "\(name).fixture-has-no-unresolved-dates"
                    )

                    if let previousWindow = windows.previous {
                        guard let previousOffsets = selection.previousOffsets,
                              let previousHistoricalOffsets = selection.previousHistoricalOffsets,
                              let previousHistoricalWindow = selection.previousHistoricalWindow else {
                            try Expect.true(false, "\(name).previous-selection-must-exist")
                            continue
                        }

                        let expectedPrevious = filterEntries(
                            entries,
                            within: previousWindow
                        )
                        let expectedPreviousHistoricalWindow = PeriodWindow(
                            from: nil,
                            to: previousWindow.from.map { start in
                                let previousDay = calendar.date(
                                    byAdding: .day,
                                    value: -1,
                                    to: start
                                )!
                                return calendar.dayEnd(previousDay)
                            }
                        )
                        let expectedPreviousHistorical = filterEntries(
                            entries,
                            within: expectedPreviousHistoricalWindow
                        )

                        try Expect.equal(
                            previousHistoricalWindow,
                            expectedPreviousHistoricalWindow,
                            "\(name).previous-opening-boundary-parity"
                        )
                        try Expect.equal(
                            selection.entries(at: previousOffsets),
                            expectedPrevious,
                            "\(name).previous-period-selection-parity"
                        )
                        try Expect.equal(
                            selection.entries(at: previousHistoricalOffsets),
                            expectedPreviousHistorical,
                            "\(name).previous-historical-selection-parity"
                        )
                        try Expect.equal(
                            selection.entries(at: previousOffsets).map(\.id),
                            expectedPrevious.map(\.id),
                            "\(name).previous-source-order-retained"
                        )
                    } else {
                        try Expect.true(
                            selection.previousOffsets == nil &&
                            selection.previousHistoricalOffsets == nil &&
                            selection.previousHistoricalWindow == nil,
                            "\(name).no-synthetic-previous-period"
                        )
                    }

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
                let driver = try await EntryCompileDriver.compile(
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
                guard let chartIndex = chart.index else {
                    try Expect.true(false, "validated period fixture requires an RGS index")
                    return
                }

                let entityIDs = driver.entities.idIndex
                let postingIndex = try RGSPeriodPostingIndex(
                    chart: chart,
                    entries: driver.resolved,
                    entityId: { entityIDs[$0] }
                )

                let indexedChart = try chart.ensuringIndex(
                    enrichNodes: true,
                    strict: false
                )
                let maps = try RGSAssembler.makeMaps(from: indexedChart)
                let routing = BusinessEntity.vof.periodOpeningRouting
                let profitShareCode = BusinessEntity.vof.profitShareCode

                // Explicit ownership oracle independent of trial-balance
                // conversion, including historical NI and existing Beg equity.
                guard let revenueID = chartIndex.byIdentifier["WOmzNodOdh"],
                      let openingID = chartIndex.byIdentifier["BEivKapOndBeg"],
                      let profitShareID = chartIndex.byIdentifier[profitShareCode] else {
                    try Expect.true(false, "opening-allocation-targets-present")
                    return
                }

                let syntheticPlain = RGSAssembler.openingBegSeed(
                    fromSourceSeeds: [
                        bankID: Decimal(100),
                        revenueID: Decimal(-100)
                    ],
                    chart: indexedChart,
                    index: chartIndex,
                    maps: maps,
                    routing: routing
                )
                try Expect.equal(
                    syntheticPlain[bankID],
                    Decimal(100),
                    "historical-bank-remains-direct"
                )
                try Expect.equal(
                    syntheticPlain[openingID],
                    Decimal(-100),
                    "historical-income-injected-into-equity-opening"
                )

                let syntheticAE = RGSAssembler.openingBegSeedAE(
                    fromSourceSeeds: [
                        AccEntKey(bankID, 7): Decimal(100),
                        AccEntKey(revenueID, 7): Decimal(-100),
                        AccEntKey(openingID, 7): Decimal(25)
                    ],
                    chart: indexedChart,
                    index: chartIndex,
                    maps: maps,
                    routing: routing,
                    profitShareCode: profitShareCode,
                    ownershipSlices: [
                        OwnershipSlice(entityId: 10, percent: Decimal(3) / 5),
                        OwnershipSlice(entityId: 11, percent: Decimal(2) / 5)
                    ]
                )
                try Expect.equal(
                    syntheticAE[AccEntKey(bankID, 7)],
                    Decimal(100),
                    "historical-bank-preserves-source-entity"
                )
                try Expect.equal(
                    syntheticAE[AccEntKey(openingID, 7)],
                    Decimal(25),
                    "historical-manual-equity-preserves-source-entity"
                )
                try Expect.equal(
                    syntheticAE[AccEntKey(profitShareID, 10)],
                    Decimal(-60),
                    "historical-profit-allocated-sixty-percent"
                )
                try Expect.equal(
                    syntheticAE[AccEntKey(profitShareID, 11)],
                    Decimal(-40),
                    "historical-profit-allocated-forty-percent"
                )
                try Expect.equal(
                    syntheticAE[AccEntKey(openingID, nil)] ?? 0,
                    Decimal(0),
                    "allocated-income-does-not-create-unassigned-equity"
                )

                for (name, shape, expectedBank, expectedProfit) in cases {
                    let windows = PeriodAssembler.resolveWindows(
                        shape: shape,
                        anchor: anchor,
                        calendar: calendar
                    )
                    let selection = PeriodEntrySelection(
                        sourceEntries: driver.resolved,
                        windows: windows,
                        calendar: calendar
                    )
                    let projection = try postingIndex.project(selection)

                    try Expect.equal(
                        projection.batch.entries,
                        driver.resolved,
                        "\(name).validated-source-entries-retained"
                    )
                    try Expect.equal(
                        projection.batch.postings.count,
                        driver.resolved.reduce(0) { $0 + $1.lines.count },
                        "\(name).source-postings-validated-once"
                    )

                    func assertSourceSeedParity(
                        _ label: String,
                        view: RGSPeriodResolvedSeedView,
                        offsets: [Int]
                    ) throws {
                        let selectedEntries = selection.entries(at: offsets)
                        let rows = trialBalance(
                            selectedEntries,
                            entityId: { entityIDs[$0] }
                        )

                        try Expect.equal(
                            view.entryOffsets,
                            offsets,
                            "\(name).\(label).original-entry-offsets"
                        )
                        try Expect.equal(
                            view.sourceSeedById,
                            RGSAssembler.seedLeafs(from: rows, using: chartIndex),
                            "\(name).\(label).native-account-seed-parity"
                        )
                        try Expect.equal(
                            view.sourceSeedAEById,
                            RGSAssembler.seedLeafsAE(
                                from: rows,
                                using: chartIndex,
                                entityId: { $0.entityId }
                            ),
                            "\(name).\(label).entity-account-seed-parity"
                        )

                        let expectedEntryOrigins = offsets.flatMap { offset in
                            Array(
                                repeating: offset,
                                count: driver.resolved[offset].lines.count
                            )
                        }
                        let actualEntryOrigins = view.postingOffsets.map { offset in
                            projection.batch.postings[offset].origin.entryIndex
                        }

                        try Expect.equal(
                            actualEntryOrigins,
                            expectedEntryOrigins,
                            "\(name).\(label).global-posting-origins-retained"
                        )
                        try Expect.equal(
                            projection.postings(in: view).count,
                            expectedEntryOrigins.count,
                            "\(name).\(label).every-selected-source-line-retained"
                        )
                    }

                    try assertSourceSeedParity(
                        "historical",
                        view: projection.historical,
                        offsets: selection.historicalOffsets
                    )
                    try assertSourceSeedParity(
                        "window",
                        view: projection.window,
                        offsets: selection.windowOffsets
                    )
                    try assertSourceSeedParity(
                        "ytd",
                        view: projection.ytd,
                        offsets: selection.ytdOffsets
                    )

                    if let previousOffsets = selection.previousOffsets {
                        guard let previous = projection.previous else {
                            try Expect.true(false, "\(name).previous-seeds-required")
                            continue
                        }
                        try assertSourceSeedParity(
                            "previous",
                            view: previous,
                            offsets: previousOffsets
                        )
                    } else {
                        try Expect.true(
                            projection.previous == nil,
                            "\(name).no-fabricated-previous-source-seeds"
                        )
                    }

                    if let historicalOffsets = selection.previousHistoricalOffsets {
                        guard let previousHistorical = projection.previousHistorical else {
                            try Expect.true(false, "\(name).previous-historical-seeds-required")
                            continue
                        }
                        try assertSourceSeedParity(
                            "previous-historical",
                            view: previousHistorical,
                            offsets: historicalOffsets
                        )
                    } else {
                        try Expect.true(
                            projection.previousHistorical == nil,
                            "\(name).no-fabricated-previous-opening-seeds"
                        )
                    }

                    let historicalRows = trialBalance(
                        selection.entries(at: selection.historicalOffsets),
                        entityId: { entityIDs[$0] }
                    )
                    let ownership = driver.entities.ownershipSlices(
                        asOf: windows.window.to ?? anchor
                    )

                    try Expect.equal(
                        RGSAssembler.openingBegSeed(
                            fromSourceSeeds: projection.historical.sourceSeedById,
                            chart: indexedChart,
                            index: chartIndex,
                            maps: maps,
                            routing: routing
                        ),
                        RGSAssembler.openingBegSeed(
                            from: historicalRows,
                            chart: indexedChart,
                            index: chartIndex,
                            maps: maps,
                            routing: routing
                        ),
                        "\(name).historical-native-opening-parity"
                    )
                    try Expect.equal(
                        RGSAssembler.openingBegSeedAE(
                            fromSourceSeeds: projection.historical.sourceSeedAEById,
                            chart: indexedChart,
                            index: chartIndex,
                            maps: maps,
                            routing: routing,
                            profitShareCode: profitShareCode,
                            ownershipSlices: ownership
                        ),
                        RGSAssembler.openingBegSeedAE(
                            from: historicalRows,
                            chart: indexedChart,
                            index: chartIndex,
                            maps: maps,
                            routing: routing,
                            profitShareCode: profitShareCode,
                            ownershipSlices: ownership,
                            entityIdOnRow: { $0.entityId }
                        ),
                        "\(name).historical-native-entity-opening-parity"
                    )

                    if let previousHistorical = projection.previousHistorical {
                        let previousRows = trialBalance(
                            selection.entries(at: previousHistorical.entryOffsets),
                            entityId: { entityIDs[$0] }
                        )
                        let previousOwnership = driver.entities.ownershipSlices(
                            asOf: windows.previous?.to ?? anchor
                        )

                        try Expect.equal(
                            RGSAssembler.openingBegSeed(
                                fromSourceSeeds: previousHistorical.sourceSeedById,
                                chart: indexedChart,
                                index: chartIndex,
                                maps: maps,
                                routing: routing
                            ),
                            RGSAssembler.openingBegSeed(
                                from: previousRows,
                                chart: indexedChart,
                                index: chartIndex,
                                maps: maps,
                                routing: routing
                            ),
                            "\(name).previous-native-opening-parity"
                        )
                        try Expect.equal(
                            RGSAssembler.openingBegSeedAE(
                                fromSourceSeeds: previousHistorical.sourceSeedAEById,
                                chart: indexedChart,
                                index: chartIndex,
                                maps: maps,
                                routing: routing,
                                profitShareCode: profitShareCode,
                                ownershipSlices: previousOwnership
                            ),
                            RGSAssembler.openingBegSeedAE(
                                from: previousRows,
                                chart: indexedChart,
                                index: chartIndex,
                                maps: maps,
                                routing: routing,
                                profitShareCode: profitShareCode,
                                ownershipSlices: previousOwnership,
                                entityIdOnRow: { $0.entityId }
                            ),
                            "\(name).previous-native-entity-opening-parity"
                        )
                    }

                    let report = try PeriodAssembler.assemble(
                        shape: shape, anchor: anchor, result: driver,
                        calendar: calendar
                    )

                    let cut = AssembleCut(
                        target: .L3,
                        includeCodes: [],
                        includeIntermediates: true,
                        omitZerosBeyondLevel1: true
                    )

                    func assertBundleParity(
                        _ label: String,
                        validated: StatementBundle,
                        legacy: StatementBundle
                    ) throws {
                        try Expect.equal(
                            validated.totalsById,
                            legacy.totalsById,
                            "\(name).\(label).balance-total-parity"
                        )
                        try Expect.equal(
                            validated.balance.map(\.id),
                            legacy.balance.map(\.id),
                            "\(name).\(label).balance-node-parity"
                        )
                        try Expect.equal(
                            validated.balance.map(\.rawAmount),
                            legacy.balance.map(\.rawAmount),
                            "\(name).\(label).balance-amount-parity"
                        )
                        try Expect.equal(
                            validated.income.map(\.id),
                            legacy.income.map(\.id),
                            "\(name).\(label).income-node-parity"
                        )
                        try Expect.equal(
                            validated.income.map(\.rawAmount),
                            legacy.income.map(\.rawAmount),
                            "\(name).\(label).income-amount-parity"
                        )
                        try Expect.equal(
                            validated.entity?.byAccount,
                            legacy.entity?.byAccount,
                            "\(name).\(label).entity-allocation-parity"
                        )
                        try Expect.equal(
                            validated.autoCloseAudit?.disposition,
                            legacy.autoCloseAudit?.disposition,
                            "\(name).\(label).auto-close-disposition-parity"
                        )
                        try Expect.equal(
                            validated.autoCloseAudit?.ni,
                            legacy.autoCloseAudit?.ni,
                            "\(name).\(label).auto-close-income-parity"
                        )
                        try Expect.equal(
                            validated.autoCloseAudit?.adjustedForManual,
                            legacy.autoCloseAudit?.adjustedForManual,
                            "\(name).\(label).auto-close-adjustment-parity"
                        )
                        try Expect.equal(
                            validated.autoCloseAudit?.manualAtNetIncome,
                            legacy.autoCloseAudit?.manualAtNetIncome,
                            "\(name).\(label).manual-income-parity"
                        )
                        try Expect.equal(
                            validated.autoCloseAudit?.manualAtEquity,
                            legacy.autoCloseAudit?.manualAtEquity,
                            "\(name).\(label).manual-equity-parity"
                        )
                    }

                    let resolvedCurrent = try PeriodAssembler.assembleSplitResolvedSeeds(
                        chart: chart,
                        incomeWindow: projection.window,
                        balanceWindow: projection.window,
                        overlayForNI: projection.window,
                        preWindowForOpening: projection.historical,
                        cut: cut,
                        omslag: .apply,
                        entity: .vof,
                        ownershipSlices: ownership
                    )
                    let presentedCurrent = PeriodAssembler.attachFinancialAverages(
                        resolvedCurrent,
                        shape: shape,
                        range: windows.window,
                        calendar: calendar
                    )
                    try assertBundleParity(
                        "current-resolved-assembly",
                        validated: presentedCurrent,
                        legacy: report.current.bundle
                    )

                    if let previousPeriod = report.previous {
                        guard let previousView = projection.previous,
                              let previousHistorical = projection.previousHistorical else {
                            try Expect.true(false, "\(name).previous-view-required")
                            continue
                        }

                        let previousOwnership = driver.entities.ownershipSlices(
                            asOf: previousPeriod.range.to ?? anchor
                        )
                        let resolvedPrevious = try PeriodAssembler.assembleSplitResolvedSeeds(
                            chart: chart,
                            incomeWindow: previousView,
                            balanceWindow: previousView,
                            overlayForNI: previousView,
                            preWindowForOpening: previousHistorical,
                            cut: cut,
                            omslag: .apply,
                            entity: .vof,
                            ownershipSlices: previousOwnership
                        )
                        let presentedPrevious = PeriodAssembler.attachFinancialAverages(
                            resolvedPrevious,
                            shape: shape,
                            range: previousPeriod.range,
                            calendar: calendar
                        )
                        try assertBundleParity(
                            "previous-resolved-assembly",
                            validated: presentedPrevious,
                            legacy: previousPeriod.bundle
                        )
                    } else {
                        try Expect.true(
                            projection.previous == nil,
                            "\(name).no-unexpected-previous-assembly"
                        )
                    }

                    // The active route must retain the original source
                    // collection and global posting origins after assembly.
                    guard let activeSources = report.sources else {
                        try Expect.true(false, "\(name).active-source-provenance-required")
                        continue
                    }
                    try Expect.equal(
                        activeSources.batch.entries,
                        driver.resolved,
                        "\(name).active-original-source-entries"
                    )
                    try Expect.equal(
                        activeSources.window.entryOffsets,
                        selection.windowOffsets,
                        "\(name).active-current-global-entry-offsets"
                    )
                    try Expect.equal(
                        activeSources.window.postingOffsets,
                        projection.window.postingOffsets,
                        "\(name).active-current-global-posting-offsets"
                    )
                    try Expect.equal(
                        activeSources.historical.sourceSeedAEById,
                        projection.historical.sourceSeedAEById,
                        "\(name).active-opening-source-entity-seeds"
                    )
                    try Expect.equal(
                        activeSources.previous?.entryOffsets,
                        projection.previous?.entryOffsets,
                        "\(name).active-previous-global-entry-offsets"
                    )
                    try Expect.equal(
                        activeSources.previousHistorical?.postingOffsets,
                        projection.previousHistorical?.postingOffsets,
                        "\(name).active-previous-opening-posting-offsets"
                    )

                    // Native period output must reuse the validated chart
                    // without changing either reporting period's statements.
                    if name == "august-to-date" {
                        let nativePeriod = try NativeOutputBuilder.buildPeriodOutput(
                            result: driver,
                            shape: shape,
                            anchor: anchor,
                            cut: cut,
                            omslag: .apply,
                            entity: .vof,
                            calendar: calendar
                        )

                        try Expect.equal(
                            nativePeriod.chart.nodes.map(\.id),
                            chart.nodes.map(\.id),
                            "\(name).native-period-chart-identities"
                        )
                        try Expect.equal(
                            nativePeriod.assembled.current.range,
                            report.current.range,
                            "\(name).native-period-current-range"
                        )
                        try assertBundleParity(
                            "native-period-current-parity",
                            validated: nativePeriod.assembled.current.bundle,
                            legacy: report.current.bundle
                        )
                        try Expect.equal(
                            nativePeriod.assembled.previous?.range,
                            report.previous?.range,
                            "\(name).native-period-previous-range"
                        )
                        if let expected = report.previous,
                           let actual = nativePeriod.assembled.previous {
                            try assertBundleParity(
                                "native-period-previous-parity",
                                validated: actual.bundle,
                                legacy: expected.bundle
                            )
                        }
                    }

                    // Keep the old public trial-balance builders as an
                    // independent accounting oracle after the route switch.
                    let compatibilityCurrent = try PeriodAssembler.buildCurrentBundle(
                        chart: chart,
                        wins: windows,
                        anchor: anchor,
                        result: driver,
                        cut: cut,
                        omslag: .apply,
                        entity: .vof,
                        shape: shape,
                        calendar: calendar
                    )
                    try assertBundleParity(
                        "active-vs-trial-balance-current",
                        validated: report.current.bundle,
                        legacy: compatibilityCurrent
                    )

                    // Exercise the migrated window-output consumer on both
                    // a complete month and a range-to-date reporting shape.
                    // The legacy trial-balance builder remains independent.
                    if name == "august" || name == "august-to-date" {
                        let nativeWindow = try NativeOutputBuilder.buildWindowOutput(
                            result: driver,
                            windows: windows,
                            anchor: anchor,
                            shape: shape,
                            cut: cut,
                            omslag: .apply,
                            entity: .vof,
                            calendar: calendar
                        )

                        try assertBundleParity(
                            "migrated-window-vs-trial-balance",
                            validated: nativeWindow.bundle,
                            legacy: compatibilityCurrent
                        )
                        try assertBundleParity(
                            "migrated-window-vs-active-period",
                            validated: nativeWindow.bundle,
                            legacy: report.current.bundle
                        )
                    }

                    let compatibilityPrevious = try PeriodAssembler.buildPreviousBundle(
                        chart: chart,
                        wins: windows,
                        anchor: anchor,
                        result: driver,
                        cut: cut,
                        omslag: .apply,
                        entity: .vof,
                        shape: shape,
                        calendar: calendar
                    )
                    if let compatibilityPrevious {
                        guard let activePrevious = report.previous else {
                            try Expect.true(false, "\(name).active-previous-required")
                            continue
                        }
                        try Expect.equal(
                            activePrevious.range,
                            compatibilityPrevious.range,
                            "\(name).active-previous-range-parity"
                        )
                        try assertBundleParity(
                            "active-vs-trial-balance-previous",
                            validated: activePrevious.bundle,
                            legacy: compatibilityPrevious.bundle
                        )
                    } else {
                        try Expect.true(
                            report.previous == nil,
                            "\(name).no-fabricated-active-previous-period"
                        )
                    }

                    let concurrent = try await PeriodAssembler.assemble_concurrent(
                        shape: shape,
                        anchor: anchor,
                        result: driver,
                        cut: cut,
                        omslag: .apply,
                        entity: .vof,
                        calendar: calendar
                    )
                    try assertBundleParity(
                        "active-sync-vs-concurrent-current",
                        validated: concurrent.current.bundle,
                        legacy: report.current.bundle
                    )
                    try Expect.equal(
                        concurrent.current.range,
                        report.current.range,
                        "\(name).sync-concurrent-current-range"
                    )
                    try Expect.equal(
                        concurrent.sources?.window.postingOffsets,
                        activeSources.window.postingOffsets,
                        "\(name).sync-concurrent-original-posting-offsets"
                    )
                    if let activePrevious = report.previous {
                        guard let concurrentPrevious = concurrent.previous else {
                            try Expect.true(false, "\(name).concurrent-previous-required")
                            continue
                        }
                        try Expect.equal(
                            concurrentPrevious.range,
                            activePrevious.range,
                            "\(name).sync-concurrent-previous-range"
                        )
                        try assertBundleParity(
                            "active-sync-vs-concurrent-previous",
                            validated: concurrentPrevious.bundle,
                            legacy: activePrevious.bundle
                        )
                    } else {
                        try Expect.true(
                            concurrent.previous == nil,
                            "\(name).concurrent-does-not-fabricate-previous"
                        )
                    }

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
