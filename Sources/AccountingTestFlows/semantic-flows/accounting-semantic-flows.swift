import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var entryResolutionFlow: TestFlow {
        TestFlow(
            "accounting-entry-resolution",
            tags: [
                "accounting",
                "entries",
                "resolution",
            ]
        ) {
            Step("resolves parsed entries through entity account and transaction stores") {
                let resolved = try ECModelFixtures.resolveEntries(
                    ECModelFixtures.validResolutionEntrySource
                )

                try Expect.equal(
                    resolved.count,
                    2,
                    "resolved entry count"
                )

                try Expect.equal(
                    resolved[0].id ?? -1,
                    9201,
                    "first resolved entry id"
                )

                try Expect.equal(
                    resolved[1].id ?? -1,
                    9202,
                    "second resolved entry id"
                )

                try Expect.true(
                    resolved[0].lines.contains {
                        $0.account == AccountKey(
                            "BLimBanRba"
                        )
                    },
                    "bank posting resolves to canonical account code"
                )

                try Expect.true(
                    resolved[1].lines.contains {
                        $0.account == AccountKey(
                            "BLimKasKas"
                        )
                    },
                    "cash posting resolves to canonical account code"
                )

                try Expect.equal(
                    resolved[0]
                        .transactionReferences
                        .map(\.id),
                    [7301],
                    "transaction references resolve to transaction keys"
                )

                try resolved[0].assertBalancing()
                try resolved[1].assertBalancing()
            }

            Step("accepts balance entity with bank account") {
                let resolved = try ECModelFixtures.resolveEntries(
                    """
                    entry {
                        id = 9220
                        date = 2026-08-15

                        for (bank_fixture) in (BLimBanRba) {
                            debit = 10.00
                        }

                        for (revenue_fixture) in (WOmzNodOdh) {
                            credit = 10.00
                        }
                    }
                    """
                )

                try Expect.equal(
                    resolved.count,
                    1,
                    "resolved balance-bank entry"
                )
            }

            Step("accepts cash entity with cash account") {
                let resolved = try ECModelFixtures.resolveEntries(
                    """
                    entry {
                        id = 9221
                        date = 2026-08-15

                        for (cash_fixture) in (BLimKasKas) {
                            debit = 10.00
                        }

                        for (revenue_fixture) in (WOmzNodOdh) {
                            credit = 10.00
                        }
                    }
                    """
                )

                try Expect.equal(
                    resolved.count,
                    1,
                    "resolved cash-cash entry"
                )
            }

            Step("rejects cash entity with bank account") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.resolveEntries(
                        ECModelFixtures.invalidCashBankEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "cash entity should not resolve against bank account"
                )
            }

            Step("rejects balance entity with cash account") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.resolveEntries(
                        ECModelFixtures.invalidBalanceCashEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "balance entity should not resolve against cash account"
                )
            }

            Step("rejects unresolved entity") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.resolveEntries(
                        ECModelFixtures.missingEntityEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "unknown entity should fail resolution"
                )
            }

            Step("rejects unresolved account") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.resolveEntries(
                        ECModelFixtures.missingAccountEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "unknown account should fail resolution"
                )
            }

            Step("rejects unresolved transaction reference") {
                let threw = ECModelFixtures.didThrow {
                    _ = try ECModelFixtures.resolveEntries(
                        ECModelFixtures.missingTransactionEntrySource
                    )
                }

                try Expect.true(
                    threw,
                    "unknown transaction reference should fail resolution"
                )
            }
        }
    }

    static var rgsIndexFlow: TestFlow {
        TestFlow(
            "accounting-rgs-index",
            tags: [
                "accounting",
                "rgs",
                "index",
            ]
        ) {
            Step("indexes identifiers references and canonical sort keys") {
                let node = try ECModelFixtures.makeIndexedNode(
                    id: 100,
                    code: "WFixtureCanonical",
                    sortKey: "W.H.A.020",
                    reference: "REF-001"
                )

                let (
                    index,
                    _
                ) = try RGSIndex.build(
                    from: [node]
                )

                try Expect.equal(
                    index.byIdentifier["WFixtureCanonical"] ?? -1,
                    100,
                    "identifier index"
                )

                try Expect.equal(
                    index.byReference["REF-001"] ?? -1,
                    100,
                    "reference index"
                )

                try Expect.equal(
                    index.bySortKey["W.H.A020"] ?? -1,
                    100,
                    "canonical sort-key index"
                )
            }

            Step("rejects duplicate identifiers in all modes") {
                let first = try ECModelFixtures.makeIndexedNode(
                    id: 101,
                    code: "WDuplicateIdentifier",
                    sortKey: "W.A"
                )

                let second = try ECModelFixtures.makeIndexedNode(
                    id: 102,
                    code: "WDuplicateIdentifier",
                    sortKey: "W.B"
                )

                let nonStrictThrew = ECModelFixtures.didThrow {
                    _ = try RGSIndex.build(
                        from: [
                            first,
                            second,
                        ],
                        strict: false
                    )
                }

                let strictThrew = ECModelFixtures.didThrow {
                    _ = try RGSIndex.build(
                        from: [
                            first,
                            second,
                        ],
                        strict: true
                    )
                }

                try Expect.true(
                    nonStrictThrew,
                    "duplicate identifier should fail non-strict build"
                )

                try Expect.true(
                    strictThrew,
                    "duplicate identifier should fail strict build"
                )
            }

            Step("duplicate sort keys are tolerated non-strict and rejected strict") {
                let first = try ECModelFixtures.makeIndexedNode(
                    id: 103,
                    code: "WDuplicateSortOne",
                    sortKey: "W.D"
                )

                let second = try ECModelFixtures.makeIndexedNode(
                    id: 104,
                    code: "WDuplicateSortTwo",
                    sortKey: "W.D"
                )

                let (
                    index,
                    _
                ) = try RGSIndex.build(
                    from: [
                        first,
                        second,
                    ],
                    strict: false
                )

                try Expect.equal(
                    index.bySortKey["W.D"] ?? -1,
                    103,
                    "non-strict duplicate sort keeps first node"
                )

                let strictThrew = ECModelFixtures.didThrow {
                    _ = try RGSIndex.build(
                        from: [
                            first,
                            second,
                        ],
                        strict: true
                    )
                }

                try Expect.true(
                    strictThrew,
                    "strict duplicate sort should fail"
                )
            }

            Step("duplicate references are tolerated non-strict and rejected strict") {
                let first = try ECModelFixtures.makeIndexedNode(
                    id: 105,
                    code: "WDuplicateReferenceOne",
                    sortKey: "W.E",
                    reference: "REF-DUP"
                )

                let second = try ECModelFixtures.makeIndexedNode(
                    id: 106,
                    code: "WDuplicateReferenceTwo",
                    sortKey: "W.F",
                    reference: "REF-DUP"
                )

                let (
                    index,
                    _
                ) = try RGSIndex.build(
                    from: [
                        first,
                        second,
                    ],
                    strict: false
                )

                try Expect.equal(
                    index.byReference.count,
                    1,
                    "non-strict duplicate reference produces one index key"
                )

                let strictThrew = ECModelFixtures.didThrow {
                    _ = try RGSIndex.build(
                        from: [
                            first,
                            second,
                        ],
                        strict: true
                    )
                }

                try Expect.true(
                    strictThrew,
                    "strict duplicate reference should fail"
                )
            }

            Step("enrichment resolves parent and level-two ids") {
                let root = try ECModelFixtures.makeIndexedNode(
                    id: 110,
                    code: "WHierarchyRoot",
                    sortKey: "W"
                )

                let levelTwo = try ECModelFixtures.makeIndexedNode(
                    id: 111,
                    code: "WHierarchyLevelTwo",
                    sortKey: "W.A"
                )

                let leaf = try ECModelFixtures.makeIndexedNode(
                    id: 112,
                    code: "WHierarchyLeaf",
                    sortKey: "W.A.B"
                )

                let (
                    _,
                    enriched
                ) = try RGSIndex.build(
                    from: [
                        root,
                        levelTwo,
                        leaf,
                    ],
                    enrichNodes: true,
                    strict: true
                )

                let nodes = enriched ?? []

                let levelTwoResolved = nodes.first {
                    $0.id == 111
                }

                let leafResolved = nodes.first {
                    $0.id == 112
                }

                try Expect.equal(
                    levelTwoResolved?
                        .xlsx?
                        .links
                        .parentId ?? -1,
                    110,
                    "level-two parent id"
                )

                try Expect.equal(
                    leafResolved?
                        .xlsx?
                        .links
                        .parentId ?? -1,
                    111,
                    "leaf parent id"
                )

                try Expect.equal(
                    leafResolved?
                        .xlsx?
                        .links
                        .l2Id ?? -1,
                    111,
                    "leaf level-two id"
                )
            }

            Step("strict enrichment rejects missing hierarchy key") {
                let orphan = try ECModelFixtures.makeIndexedNode(
                    id: 120,
                    code: "WOrphanFixture",
                    sortKey: "W.M.O"
                )

                let threw = ECModelFixtures.didThrow {
                    _ = try RGSIndex.build(
                        from: [orphan],
                        enrichNodes: true,
                        strict: true
                    )
                }

                try Expect.true(
                    threw,
                    "strict hierarchy enrichment should reject missing parent"
                )
            }
        }
    }

    static var canonicalRootsFlow: TestFlow {
        TestFlow(
            "accounting-canonical-roots",
            tags: [
                "accounting",
                "configuration",
                "rgs",
            ]
        ) {
            Step("VOF auto-close and capital roots remain canonical") {
                let roots = BusinessEntity.vof.canonicalRoots

                try Expect.equal(
                    roots.autoCloseTargets.netIncomeCode,
                    "WNerKapKap",
                    "net income target"
                )

                try Expect.equal(
                    roots.autoCloseTargets.retainedEarningsCode,
                    "BEivKapOndAow",
                    "retained earnings target"
                )

                try Expect.equal(
                    roots.capital.profitShareCode,
                    "BEivKapOndAow",
                    "profit-share target"
                )

                try Expect.equal(
                    roots.capital.contributionRootCode,
                    "BEivKapPrs",
                    "capital contribution root"
                )

                try Expect.equal(
                    roots.capital.drawingRootCode,
                    "BEivKapPro",
                    "capital drawing root"
                )

                try Expect.equal(
                    roots.capital.equityTotalFallbackCode ?? "",
                    "BEivKap",
                    "equity fallback root"
                )
            }

            Step("VOF opening and analytics roots remain canonical") {
                let roots = BusinessEntity.vof.canonicalRoots

                try Expect.equal(
                    roots.periodOpeningRouting.equityAnchorCode,
                    "BEiv",
                    "opening equity anchor"
                )

                try Expect.equal(
                    roots.periodOpeningRouting.equityOpeningCode ?? "",
                    "BEivKapOndBeg",
                    "opening equity account"
                )

                try Expect.equal(
                    roots.periodOpeningRouting.exceptionKeepLeafAnchors,
                    ["BLim"],
                    "opening leaf exceptions"
                )

                try Expect.equal(
                    roots.analytics.netTurnoverCode,
                    "WOmz",
                    "net turnover root"
                )

                try Expect.equal(
                    roots.analytics.costOfRevenueCode,
                    "WKpr",
                    "cost-of-revenue root"
                )

                try Expect.equal(
                    roots.analytics.operatingExpensesCode,
                    "WBed",
                    "operating-expense root"
                )

                try Expect.equal(
                    roots.analytics.depreciationExpensesCode,
                    "WAfs",
                    "depreciation root"
                )

                try Expect.equal(
                    roots.analytics.financialResultCode,
                    "WFbe",
                    "financial-result root"
                )

                try Expect.equal(
                    roots.analytics.liquidAssetsCodes,
                    ["BLim"],
                    "liquid-assets roots"
                )
            }

            Step("VOF VAT roots remain canonical") {
                let vat = BusinessEntity.vof.vatRoots

                try Expect.equal(
                    vat.payableCodes,
                    [
                        "BSchBepBtw",
                        "BSchBepEob",
                        "BSchBepBaf",
                    ],
                    "VAT payable roots"
                )

                try Expect.equal(
                    vat.receivableCodes,
                    [
                        "BVorVbkTvo",
                        "BVorVbkEob",
                    ],
                    "VAT receivable roots"
                )

                try Expect.equal(
                    vat.outputCodes,
                    [
                        "BSchBepBtwOla",
                        "BSchBepEob",
                        "BSchBepBaf",
                    ],
                    "VAT output roots"
                )

                try Expect.equal(
                    vat.deductibleCodes,
                    [
                        "BSchBepBtwVoo",
                    ],
                    "VAT deductible roots"
                )

                try Expect.equal(
                    vat.privateUseCodes,
                    [
                        "BSchBepBtwOop",
                    ],
                    "VAT private-use roots"
                )
            }
        }
    }

    static var compilerFixtureFlow: TestFlow {
        TestFlow(
            "accounting-compiler-fixture",
            tags: [
                "accounting",
                "compiler",
                "integration",
            ]
        ) {
            Step("compiles a complete synthetic project") {
                let root = try ECModelFixtures.makeCompilerProjectFixture()

                defer {
                    try? FileManager.default.removeItem(
                        at: root
                    )
                }

                let result = try EntryCompileDriver.compile(
                    projectRoot: root,
                    verbose: false,
                    placeholderWarnings: .silent
                )

                try Expect.equal(
                    result.entities.byFull.count,
                    1,
                    "compiled entity count"
                )

                try Expect.equal(
                    result.accounts.byCode.count,
                    3,
                    "compiled account count"
                )

                try Expect.equal(
                    result.transactions.count,
                    1,
                    "compiled transaction count"
                )

                try Expect.equal(
                    result.entries.count,
                    1,
                    "parsed entry count"
                )

                try Expect.equal(
                    result.resolved.count,
                    1,
                    "resolved entry count"
                )

                let entry = result.resolved[0]

                try Expect.equal(
                    entry.id ?? -1,
                    9401,
                    "compiled entry id"
                )

                try Expect.equal(
                    entry.transactionReferences.map(\.id),
                    [7401],
                    "compiled transaction reference"
                )

                try Expect.true(
                    entry.lines.contains {
                        $0.account == AccountKey(
                            "BLimBanRba"
                        )
                    },
                    "compiled bank posting"
                )

                try Expect.true(
                    entry.lines.contains {
                        $0.account == AccountKey(
                            "WOmzNodOdh"
                        )
                    },
                    "compiled revenue posting"
                )

                try entry.assertBalancing()
            }
        }
    }
}
