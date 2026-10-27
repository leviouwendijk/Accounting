import Accounting
import AccountingParsers
import Foundation

enum ECModelFixtures {
    static let utc = TimeZone(secondsFromGMT: 0)!

    static let entryURL = URL(
        fileURLWithPath: "/fixtures/accounting/entries/2026/8/main.ec"
    )

    static let entityURL = URL(
        fileURLWithPath:
            "/fixtures/accounting/config/entities/deliverables/product/archive.ec"
    )

    static let transactionURL = URL(
        fileURLWithPath: "/fixtures/accounting/transactions/2026/8/bunq.ec"
    )

    static let entrySource = """
    entry {
        id = 9001
        date = 2026-08-15
        sort regular

        for (
            fixtures.item.alpha,
            fixtures.item.beta
        ) in (
            BLimBanRba,
            WBedAlkOal
        ) {
            debit = 10.00
        }

        in (WOmzNodOdh) for (fixtures.service.gamma) {
            credit = 20.00
        }

        in (WKprKvgKvg) {
            for (fixtures.item.alpha) {
                debit = 5.00
            }

            for (fixtures.item.beta) {
                debit = 7.00
            }
        }

        posting {
            account = BEivKapOndAow
            entity = fixtures.owner.delta
            cr = 12.00
        }

        transactions {
            ref 41, 42, 41,
            ref 43
        }

        metadata {
            source = synthetic
            shared = first
        }

        metadata {
            shared = second
            batch = grammar
        }
    }
    """

    static let invalidEntrySource = """
    entry {
        id = 9002
        date = 2026-08-15

        line {
            account = BLimBanRba
            entity = fixtures.item.alpha
        }
    }
    """

    static let entitySource = """
    entity {
        use alias fixture_leash

        type tangible
        domain physical

        details {
            Synthetic fixture product
        }

        content {
            service.session = 2
            product.adapter = 1
        }

        variant {
            use alias any
        }

        variant {
            use alias 10mm

            metadata {
                sku = fixture_10
                color = blue
            }

            subvariant {
                use alias black
            }
        }
    }

    entity {
        use alias fixture_manual

        domain digital

        details {
            Synthetic digital fixture
        }
    }
    """

    static let sharedEntitySource = """
    entity {
        use alias shared_supplier
    }
    """

    static let transactionSource = """
    transaction {
        id = 7001
        date = 2026-08-15
        source = bunq

        identifiers {
            platform_account_id = 11001
            platform_transaction_id = 22002
        }

        amount {
            currency = EUR
            gross = 120.50
            fee = 0.50
            net = 120.00
        }

        details {
            Synthetic transaction
        }

        counterparty {
            name = FixtureSupplier
            iban = NL00TEST0123456789
            bic = TESTNL2A
        }

        metadata {
            fixture = full
            category = synthetic
        }

        status = cleared
    }

    transaction {
        id = 7002
        date infer 16
        source = cash

        amount {
            currency = EUR
            gross = 25.00
        }
    }
    """

    static let invalidTransactionSource = """
    transaction {
        id = 7003
        date = 2026-08-15
        source = bunq
    }
    """

    static let vatDefaultSource = """
    entry {
        id = 9101
        date = 2026-08-15

        line {
            account = WOmzNodOdh
            entity = fixtures.service.gamma
            cr = 1.00
        }

        vat {
            period {
                year = 2026
                quarter = 3
            }
        }
    }
    """

    static let vatFilingSource = """
    entry {
        id = 9102
        date = 2026-08-15

        line {
            account = WOmzNodOdh
            entity = fixtures.service.gamma
            cr = 1.00
        }

        vat {
            kind = filing

            period {
                year = 2025
                quarter = 4
            }
        }
    }
    """

    static let vatCorrectionSource = """
    entry {
        id = 9103
        date = 2026-08-15

        line {
            account = WOmzNodOdh
            entity = fixtures.service.gamma
            cr = 1.00
        }

        vat {
            kind = correction

            period {
                year = 2024
                quarter = 1
            }
        }
    }
    """

    static let invalidVATQuarterSource = """
    entry {
        id = 9104
        date = 2026-08-15

        line {
            account = WOmzNodOdh
            entity = fixtures.service.gamma
            cr = 1.00
        }

        vat {
            period {
                year = 2026
                quarter = 5
            }
        }
    }
    """

    static let missingVATPeriodSource = """
    entry {
        id = 9105
        date = 2026-08-15

        line {
            account = WOmzNodOdh
            entity = fixtures.service.gamma
            cr = 1.00
        }

        vat {
            kind = filing
        }
    }
    """

    static func parseEntries(
        _ source: String,
        fileURL: URL = entryURL
    ) throws -> [Entry] {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: .entries
        )

        let prepared = try lexer.prepareTokenStream(
            trace: true,
            filePath: fileURL.path
        )

        let parser = EntryCompilerEntriesParser(
            tokens: prepared.tokens,
            defaultTimeZone: utc,
            fileURL: fileURL,
            lineMap: prepared.lineMap,
            spanMap: prepared.spanMap
        )

        return try parser.parseEntries()
    }

    static func parseEntities(
        _ source: String,
        fileURL: URL
    ) throws -> [EntityDef] {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: .entities
        )

        let prepared = try lexer.prepareTokenStream(
            trace: true,
            filePath: fileURL.path
        )

        let parser = EntryCompilerEntitiesFileParser(
            tokens: prepared.tokens,
            defaultTZ: utc,
            fileURL: fileURL,
            lineMap: prepared.lineMap,
            spanMap: prepared.spanMap
        )

        return try parser.parseEntitiesFile()
    }

    static func parseTransactions(
        _ source: String,
        fileURL: URL = transactionURL
    ) throws -> [Transaction] {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: .transactions
        )

        let prepared = try lexer.prepareTokenStream(
            trace: true,
            filePath: fileURL.path
        )

        let parser = EntryCompilerTransactionsFileParser(
            tokens: prepared.tokens,
            fileURL: fileURL,
            lineMap: prepared.lineMap,
            spanMap: prepared.spanMap
        )

        return try parser.parseTransactionsFile()
    }

    static func didThrow(
        _ body: () throws -> Void
    ) -> Bool {
        do {
            try body()
            return false
        } catch {
            return true
        }
    }
}
