import Accounting
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var entryGrammarFlow: TestFlow {
        TestFlow(
            "accounting-entry-grammar",
            tags: ["accounting", "parser", "entry"]
        ) {
            Step("parses representative entry grammar") {
                let entries = try ECModelFixtures.parseEntries(
                    ECModelFixtures.entrySource
                )

                try Expect.equal(
                    entries.count,
                    1,
                    "entry count"
                )

                let entry = entries[0]

                try Expect.equal(
                    entry.id ?? -1,
                    9001,
                    "entry id"
                )

                try Expect.equal(
                    entry.lines.count,
                    8,
                    "expanded line count"
                )

                try Expect.equal(
                    entry.transactionReferences,
                    [41, 42, 43],
                    "transaction references deduplicate in source order"
                )

                try Expect.equal(
                    entry.metadata["source"] ?? "",
                    "synthetic",
                    "first metadata block survives"
                )

                try Expect.equal(
                    entry.metadata["shared"] ?? "",
                    "second",
                    "later metadata wins for duplicate key"
                )

                try Expect.equal(
                    entry.metadata["batch"] ?? "",
                    "grammar",
                    "later metadata adds keys"
                )
            }

            Step("rejects a line without direction and amount") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.parseEntries(
                        ECModelFixtures.invalidEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "invalid entry should fail parsing"
                )
            }
        }
    }

    static var vatGrammarFlow: TestFlow {
        TestFlow(
            "accounting-vat-grammar",
            tags: ["accounting", "parser", "vat"]
        ) {
            Step("defaults VAT kind to settlement") {
                let entries = try ECModelFixtures.parseEntries(
                    ECModelFixtures.vatDefaultSource
                )

                try Expect.equal(entries.count, 1, "entry count")

                let vat = entries[0].vat

                try Expect.true(
                    vat != nil,
                    "VAT annotation exists"
                )

                try Expect.equal(
                    vat!.kind.rawValue,
                    "settlement",
                    "default VAT kind"
                )

                try Expect.equal(
                    vat!.period.year,
                    2026,
                    "VAT year"
                )

                try Expect.equal(
                    Int(vat!.period.quarter.rawValue),
                    3,
                    "VAT quarter"
                )
            }

            Step("parses filing VAT") {
                let entries = try ECModelFixtures.parseEntries(
                    ECModelFixtures.vatFilingSource
                )

                let vat = entries[0].vat

                try Expect.true(vat != nil, "VAT annotation exists")
                try Expect.equal(vat!.kind.rawValue, "filing", "VAT kind")
                try Expect.equal(vat!.period.year, 2025, "VAT year")
                try Expect.equal(
                    Int(vat!.period.quarter.rawValue),
                    4,
                    "VAT quarter"
                )
            }

            Step("parses correction VAT") {
                let entries = try ECModelFixtures.parseEntries(
                    ECModelFixtures.vatCorrectionSource
                )

                let vat = entries[0].vat

                try Expect.true(vat != nil, "VAT annotation exists")
                try Expect.equal(
                    vat!.kind.rawValue,
                    "correction",
                    "VAT kind"
                )
                try Expect.equal(vat!.period.year, 2024, "VAT year")
                try Expect.equal(
                    Int(vat!.period.quarter.rawValue),
                    1,
                    "VAT quarter"
                )
            }

            Step("rejects invalid VAT quarter") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.parseEntries(
                        ECModelFixtures.invalidVATQuarterSource
                    )
                }

                try Expect.true(
                    threw,
                    "quarter 5 should fail"
                )
            }

            Step("requires VAT period") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.parseEntries(
                        ECModelFixtures.missingVATPeriodSource
                    )
                }

                try Expect.true(
                    threw,
                    "VAT without period should fail"
                )
            }
        }
    }

    static var entityGrammarFlow: TestFlow {
        TestFlow(
            "accounting-entity-grammar",
            tags: ["accounting", "parser", "entity"]
        ) {
            Step("parses inferred entity family and rich properties") {
                let defs = try ECModelFixtures.parseEntities(
                    ECModelFixtures.entitySource,
                    fileURL: ECModelFixtures.entityURL
                )

                try Expect.equal(
                    defs.count,
                    5,
                    "base entities plus variants and subvariant"
                )

                let base = defs.first {
                    $0.key.alias.name == "fixture_leash"
                }

                try Expect.true(
                    base != nil,
                    "base fixture entity exists"
                )

                try Expect.equal(
                    base!.key.class,
                    "deliverables",
                    "class inferred from path"
                )

                try Expect.equal(
                    base!.key.family,
                    "product",
                    "family inferred from path"
                )

                try Expect.equal(
                    base!.metadata["type"] ?? "",
                    "tangible",
                    "type metadata"
                )

                try Expect.equal(
                    base!.metadata["domain"] ?? "",
                    "physical",
                    "domain metadata"
                )

                try Expect.equal(
                    base!.metadata["content.service.session"] ?? "",
                    "2",
                    "service content metadata"
                )

                try Expect.equal(
                    base!.metadata["content.product.adapter"] ?? "",
                    "1",
                    "product content metadata"
                )

                try Expect.true(
                    base!.details?.contains(
                        "Synthetic fixture product"
                    ) == true,
                    "details parsed"
                )

                let aliases = defs.map {
                    $0.key.alias.string
                }

                try Expect.true(
                    aliases.contains {
                        $0.contains("10mm")
                    },
                    "variant definition exists"
                )

                try Expect.true(
                    aliases.contains {
                        $0.contains("black")
                    },
                    "subvariant definition exists"
                )

                try Expect.true(
                    defs.contains {
                        $0.metadata["sku"] == "fixture_10"
                    },
                    "variant metadata survives"
                )
            }

            Step("deeper directories do not replace inferred family") {
                let url = URL(
                    fileURLWithPath:
                        "/fixtures/config/entities/objects/usable/deep/item.ec"
                )

                let inferred = inferClassFamily(from: url)

                try Expect.equal(
                    inferred.0 ?? "",
                    "objects",
                    "inferred class"
                )

                try Expect.equal(
                    inferred.1 ?? "",
                    "usable",
                    "inferred family"
                )
            }
        }
    }

    static var transactionGrammarFlow: TestFlow {
        TestFlow(
            "accounting-transaction-grammar",
            tags: ["accounting", "parser", "transaction"]
        ) {
            Step("parses full and minimal transactions") {
                let transactions = try ECModelFixtures.parseTransactions(
                    ECModelFixtures.transactionSource
                )

                try Expect.equal(
                    transactions.count,
                    2,
                    "transaction count"
                )

                let full = transactions[0]
                let minimal = transactions[1]

                try Expect.equal(
                    full.id ?? -1,
                    7001,
                    "full transaction id"
                )

                try Expect.equal(
                    full.source.rawValue,
                    "bunq",
                    "full transaction source"
                )

                try Expect.equal(
                    full.status.rawValue,
                    "cleared",
                    "explicit transaction status"
                )

                try Expect.equal(
                    full.identifiers.platformAccountID ?? -1,
                    11001,
                    "platform account id"
                )

                try Expect.equal(
                    full.identifiers.platformTransactionID ?? -1,
                    22002,
                    "platform transaction id"
                )

                try Expect.equal(
                    full.amount.gross,
                    Decimal(string: "120.50")!,
                    "gross amount"
                )

                try Expect.equal(
                    full.amount.fee ?? 0,
                    Decimal(string: "0.50")!,
                    "fee amount"
                )

                try Expect.equal(
                    full.amount.net ?? 0,
                    Decimal(string: "120.00")!,
                    "net amount"
                )

                try Expect.equal(
                    full.metadata["fixture"] ?? "",
                    "full",
                    "transaction metadata"
                )

                try Expect.equal(
                    minimal.id ?? -1,
                    7002,
                    "minimal transaction id"
                )

                try Expect.equal(
                    minimal.source.rawValue,
                    "cash",
                    "minimal transaction source"
                )

                try Expect.equal(
                    minimal.status.rawValue,
                    "pending",
                    "missing status defaults to pending"
                )
            }

            Step("requires transaction amount") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.parseTransactions(
                        ECModelFixtures.invalidTransactionSource
                    )
                }

                try Expect.true(
                    threw,
                    "transaction without amount should fail"
                )
            }
        }
    }

    static var entityStoreResolutionFlow: TestFlow {
        TestFlow(
            "accounting-entity-store-resolution",
            tags: ["accounting", "entity", "resolution"]
        ) {
            Step("resolves full and alias-only references") {
                let defs = try ECModelFixtures.parseEntities(
                    ECModelFixtures.entitySource,
                    fileURL: ECModelFixtures.entityURL
                )

                var builder = EntityStoreBuilder()

                for def in defs {
                    try builder.add(def)
                }

                let store = builder.freeze()

                try Expect.equal(
                    store.byFull.count,
                    5,
                    "entity store count"
                )

                let full = try store.resolve(
                    EntityRef(
                        class: "deliverables",
                        family: "product",
                        alias: EntityAlias.parse("fixture_leash")
                    ),
                    at: nil
                )

                try Expect.equal(
                    full.key.alias.name,
                    "fixture_leash",
                    "full reference resolution"
                )

                let aliasOnly = try store.resolve(
                    EntityRef(
                        class: nil,
                        family: nil,
                        alias: EntityAlias.parse("fixture_leash")
                    ),
                    at: nil
                )

                try Expect.equal(
                    aliasOnly.key.alias.name,
                    "fixture_leash",
                    "alias-only resolution"
                )
            }

            Step("rejects missing entity reference") {
                let defs = try ECModelFixtures.parseEntities(
                    ECModelFixtures.entitySource,
                    fileURL: ECModelFixtures.entityURL
                )

                var builder = EntityStoreBuilder()

                for def in defs {
                    try builder.add(def)
                }

                let store = builder.freeze()

                let threw = ECModelFixtures.didThrow {
                    _ = try store.resolve(
                        EntityRef(
                            class: nil,
                            family: nil,
                            alias: EntityAlias.parse("does_not_exist")
                        ),
                        at: nil
                    )
                }

                try Expect.true(
                    threw,
                    "missing entity should fail resolution"
                )
            }

            Step("rejects duplicate full entity key") {
                let defs = try ECModelFixtures.parseEntities(
                    ECModelFixtures.entitySource,
                    fileURL: ECModelFixtures.entityURL
                )

                var builder = EntityStoreBuilder()

                try builder.add(defs[0])

                let threw = ECModelFixtures.didThrow {
                    try builder.add(defs[0])
                }

                try Expect.true(
                    threw,
                    "duplicate entity key should fail"
                )
            }

            Step("rejects ambiguous alias-only reference") {
                let companyURL = URL(
                    fileURLWithPath:
                        "/fixtures/config/entities/groups/company/shared.ec"
                )

                let supplierURL = URL(
                    fileURLWithPath:
                        "/fixtures/config/entities/vendors/supplier/shared.ec"
                )

                let company = try ECModelFixtures.parseEntities(
                    ECModelFixtures.sharedEntitySource,
                    fileURL: companyURL
                )

                let supplier = try ECModelFixtures.parseEntities(
                    ECModelFixtures.sharedEntitySource,
                    fileURL: supplierURL
                )

                var builder = EntityStoreBuilder()

                for def in company + supplier {
                    try builder.add(def)
                }

                let store = builder.freeze()

                let threw = ECModelFixtures.didThrow {
                    _ = try store.resolve(
                        EntityRef(
                            class: nil,
                            family: nil,
                            alias: EntityAlias.parse("shared_supplier")
                        ),
                        at: nil
                    )
                }

                try Expect.true(
                    threw,
                    "ambiguous alias should fail resolution"
                )
            }
        }
    }

    static var transactionStoreInvariantFlow: TestFlow {
        TestFlow(
            "accounting-transaction-store-invariants",
            tags: ["accounting", "transaction", "store"]
        ) {
            Step("stores and resolves parsed transactions") {
                let transactions = try ECModelFixtures.parseTransactions(
                    ECModelFixtures.transactionSource
                )

                var builder = TransactionStoreBuilder()

                try builder.addAll(transactions)

                let store = try builder.freeze()

                try Expect.equal(
                    store.count,
                    2,
                    "transaction store count"
                )

                let resolved = try store.resolve(
                    id: 7001,
                    at: nil
                )

                try Expect.equal(
                    resolved.id ?? -1,
                    7001,
                    "resolved transaction id"
                )

                let keys = try store.resolveAll(
                    ids: [7001, 7002],
                    at: nil
                )

                try Expect.equal(
                    keys.count,
                    2,
                    "resolved transaction reference count"
                )
            }

            Step("rejects missing transaction id") {
                let transactions = try ECModelFixtures.parseTransactions(
                    ECModelFixtures.transactionSource
                )

                var builder = TransactionStoreBuilder()

                try builder.addAll(transactions)

                let store = try builder.freeze()

                let threw = ECModelFixtures.didThrow {
                    _ = try store.resolve(
                        id: 9999,
                        at: nil
                    )
                }

                try Expect.true(
                    threw,
                    "missing transaction should fail resolution"
                )
            }

            Step("rejects duplicate transaction id") {
                let transactions = try ECModelFixtures.parseTransactions(
                    ECModelFixtures.transactionSource
                )

                var builder = TransactionStoreBuilder()

                try builder.add(transactions[0])

                let threw = ECModelFixtures.didThrow {
                    try builder.add(transactions[0])
                }

                try Expect.true(
                    threw,
                    "duplicate transaction id should fail"
                )
            }
        }
    }
}
