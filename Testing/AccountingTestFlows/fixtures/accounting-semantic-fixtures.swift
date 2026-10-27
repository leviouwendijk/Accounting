import Accounting
import AccountingCompiler
import AccountingParsers
import Foundation

extension ECModelFixtures {
    static let semanticSettingsURL = URL(
        fileURLWithPath: "/fixtures/accounting/config/settings.ec"
    )

    static let semanticSettingsSource = """
    settings {
        entry {
            default_timezone = Europe/Amsterdam
        }

        aggregation {
            chart {
                find rgs
                version {
                    major = 3
                    minor = 8
                }
            }

            include_previous_periods = true
        }
    }
    """

    static let bankEntityURL = URL(
        fileURLWithPath:
            "/fixtures/accounting/config/entities/liquids/balance/definition.ec"
    )

    static let cashEntityURL = URL(
        fileURLWithPath:
            "/fixtures/accounting/config/entities/liquids/cash/definition.ec"
    )

    static let revenueEntityURL = URL(
        fileURLWithPath:
            "/fixtures/accounting/config/entities/fixtures/general/definition.ec"
    )

    static let bankEntitySource = """
    entity {
        use alias bank_fixture
    }
    """

    static let cashEntitySource = """
    entity {
        use alias cash_fixture
    }
    """

    static let revenueEntitySource = """
    entity {
        use alias revenue_fixture
    }
    """

    static let resolutionTransactionSource = """
    transaction {
        id = 7301
        date = 2026-08-15
        source = manual

        amount {
            currency = EUR
            gross = 10.00
        }
    }
    """

    static let validResolutionEntrySource = """
    entry {
        id = 9201
        date = 2026-08-15

        for (bank_fixture) in (BLimBanRba) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }

        transactions {
            ref 7301
        }
    }

    entry {
        id = 9202
        date = 2026-08-15

        for (cash_fixture) in (BLimKasKas) {
            debit = 5.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 5.00
        }
    }
    """

    static let invalidCashBankEntrySource = """
    entry {
        id = 9210
        date = 2026-08-15

        for (cash_fixture) in (BLimBanRba) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }
    }
    """

    static let invalidBalanceCashEntrySource = """
    entry {
        id = 9211
        date = 2026-08-15

        for (bank_fixture) in (BLimKasKas) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }
    }
    """

    static let missingEntityEntrySource = """
    entry {
        id = 9212
        date = 2026-08-15

        for (does_not_exist) in (BLimBanRba) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }
    }
    """

    static let missingAccountEntrySource = """
    entry {
        id = 9213
        date = 2026-08-15

        for (revenue_fixture) in (BMissingFixture) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }
    }
    """

    static let missingTransactionEntrySource = """
    entry {
        id = 9214
        date = 2026-08-15

        for (bank_fixture) in (BLimBanRba) {
            debit = 10.00
        }

        for (revenue_fixture) in (WOmzNodOdh) {
            credit = 10.00
        }

        transactions {
            ref 9999
        }
    }
    """

    static func parseSettings(
        _ source: String = semanticSettingsSource,
        fileURL: URL = semanticSettingsURL
    ) throws -> EntryCompilerSettings {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: .settings
        )

        let prepared = try lexer.prepareTokenStream(
            trace: true,
            filePath: fileURL.path
        )

        let parser = EntryCompilerSettingsParser(
            tokens: prepared.tokens,
            fileURL: fileURL,
            lineMap: prepared.lineMap,
            spanMap: prepared.spanMap
        )

        return try parser.parseSettingsBlock()
    }

    static func semanticEntityStore() throws -> EntityStore {
        let bank = try parseEntities(
            bankEntitySource,
            fileURL: bankEntityURL
        )

        let cash = try parseEntities(
            cashEntitySource,
            fileURL: cashEntityURL
        )

        let revenue = try parseEntities(
            revenueEntitySource,
            fileURL: revenueEntityURL
        )

        var builder = EntityStoreBuilder()

        for definition in bank + cash + revenue {
            try builder.add(definition)
        }

        return builder.freeze()
    }

    static func semanticTransactionStore() throws -> TransactionStore {
        let transactions = try parseTransactions(
            resolutionTransactionSource
        )

        var builder = TransactionStoreBuilder()

        try builder.addAll(
            transactions
        )

        return try builder.freeze()
    }

    static func postingNodes() throws -> [RGSNode] {
        [
            try makePostingNode(
                id: 1,
                code: "BLimBanRba",
                direction: .debit
            ),
            try makePostingNode(
                id: 2,
                code: "BLimKasKas",
                direction: .debit
            ),
            try makePostingNode(
                id: 3,
                code: "WOmzNodOdh",
                direction: .credit
            ),
        ]
    }

    static func semanticAccountStore() throws -> AccountStore {
        let settings = try parseSettings()

        let chart = try CompiledChart(
            name: "Synthetic Accounting Test Chart",
            version: settings.aggregation.chartVersion,
            nodes: postingNodes()
        )

        return try AccountStore(
            chart: chart
        )
    }

    static func resolveEntries(
        _ source: String
    ) throws -> [ResolvedEntry] {
        let entries = try parseEntries(
            source
        )

        return try EntryResolutionPass.resolve(
            entries,
            entities: semanticEntityStore(),
            accounts: semanticAccountStore(),
            transactions: semanticTransactionStore(),
            settings: parseSettings()
        )
    }

    static func makePostingNode(
        id: Int,
        code: String,
        direction: Direction
    ) throws -> RGSNode {
        let side: RGSNodeSide = code.hasPrefix("B")
            ? .balance
            : .profitLoss

        let temporality: Temporality = side == .balance
            ? .instant
            : .duration

        return try RGSNode(
            id: id,
            codes: .init(
                code: code
            ),
            labels: .init(
                short: code,
                long: code
            ),
            direction: direction,
            level: 1,
            temporality: temporality,
            side: side,
            omslagId: nil,
            directionSign: nil,
            xlsx: nil,
            xbrl: nil
        )
    }

    static func makeIndexedNode(
        id: Int,
        code: String,
        sortKey: String,
        reference: String? = nil,
        direction: Direction = .credit
    ) throws -> RGSNode {
        let sorting = RGSNodeSortingCode(
            key: sortKey
        )

        let side: RGSNodeSide = code.hasPrefix("B")
            ? .balance
            : .profitLoss

        let temporality: Temporality = side == .balance
            ? .instant
            : .duration

        let links = RGSNodeLinksXLSXSortingKey(
            parentKey: sorting.parentKeyString,
            l2Key: sorting.l2Key(
                fallbackSide: String(
                    code.prefix(1)
                )
            )
        )

        let xlsx = RGSNodeXLSXConcept(
            sortingCode: sorting,
            links: links,
            filters: nil,
            reference: reference
        )

        return try RGSNode(
            id: id,
            codes: .init(
                code: code
            ),
            labels: .init(
                short: code,
                long: code
            ),
            direction: direction,
            level: UInt8(
                max(
                    1,
                    sorting.segments.count
                )
            ),
            temporality: temporality,
            side: side,
            omslagId: nil,
            directionSign: nil,
            xlsx: xlsx,
            xbrl: nil
        )
    }

    static func makeCompilerProjectFixture() throws -> URL {
        let root = FileManager.default
            .temporaryDirectory
            .appendingPathComponent(
                "AccountingTestFlows-\(UUID().uuidString)",
                isDirectory: true
            )

        let project = EntryCompilerProject(
            root: root
        )

        let settings = try parseSettings()

        try writeFixtureText(
            semanticSettingsSource,
            to: project.url(
                .config,
                .settings
            )
        )

        let entityURL = project
            .url(
                .config,
                .entities
            )
            .appendingPathComponent(
                "fixtures",
                isDirectory: true
            )
            .appendingPathComponent(
                "general",
                isDirectory: true
            )
            .appendingPathComponent(
                "definition.ec",
                isDirectory: false
            )

        try writeFixtureText(
            """
            entity {
                use alias compiler_fixture
            }
            """,
            to: entityURL
        )

        let transactionURL = project
            .url(.transactions)
            .appendingPathComponent(
                "2026",
                isDirectory: true
            )
            .appendingPathComponent(
                "8",
                isDirectory: true
            )
            .appendingPathComponent(
                "fixture.ec",
                isDirectory: false
            )

        try writeFixtureText(
            """
            transaction {
                id = 7401
                date = 2026-08-15
                source = manual

                amount {
                    currency = EUR
                    gross = 25.00
                }
            }
            """,
            to: transactionURL
        )

        let entryURL = project
            .url(.entries)
            .appendingPathComponent(
                "2026",
                isDirectory: true
            )
            .appendingPathComponent(
                "8",
                isDirectory: true
            )
            .appendingPathComponent(
                "fixture.ec",
                isDirectory: false
            )

        try writeFixtureText(
            """
            entry {
                id = 9401
                date = 2026-08-15

                for (compiler_fixture) in (BLimBanRba) {
                    debit = 25.00
                }

                for (compiler_fixture) in (WOmzNodOdh) {
                    credit = 25.00
                }

                transactions {
                    ref 7401
                }
            }
            """,
            to: entryURL
        )

        let chart = try CompiledChart(
            name: "Synthetic Accounting Compiler Chart",
            version: settings.aggregation.chartVersion,
            nodes: postingNodes()
        )

        let chartURL = project.resource(
            finding: settings.aggregation.chartFind,
            version: settings.aggregation.chartVersion
        )

        try FileManager.default.createDirectory(
            at: chartURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
        ]

        try encoder
            .encode(chart)
            .write(
                to: chartURL,
                options: .atomic
            )

        return root
    }

    static func writeFixtureText(
        _ text: String,
        to url: URL
    ) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        try text.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }
}
