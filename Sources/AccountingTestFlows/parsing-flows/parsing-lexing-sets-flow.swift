import Accounting
import TestFlows

extension AccountingTestFlowsSuite {
    static var parsingLexingSetsFlow: TestFlow {
        TestFlow(
            "parsing-lexing-sets",
            tags: [
                "parsing",
                "lexer",
                "flavors",
            ]
        ) {
            Step("accounts flavor promotes account and leaves entity as ident") {
                let sets = EntryCompilerLexingSetsCache.pointer(
                    for: .accounts
                )

                try Expect.true(
                    sets.keywords.contains("account"),
                    "parsing-lexing-sets.accounts.account-keyword"
                )

                try Expect.true(
                    sets.idents.contains("entity"),
                    "parsing-lexing-sets.accounts.entity-ident"
                )

                try Expect.false(
                    sets.keywords.contains("entity"),
                    "parsing-lexing-sets.accounts.entity-not-keyword"
                )
            }

            Step("entities flavor promotes entity and leaves account as ident") {
                let sets = EntryCompilerLexingSetsCache.pointer(
                    for: .entities
                )

                try Expect.true(
                    sets.keywords.contains("entity"),
                    "parsing-lexing-sets.entities.entity-keyword"
                )

                try Expect.true(
                    sets.idents.contains("account"),
                    "parsing-lexing-sets.entities.account-ident"
                )

                try Expect.false(
                    sets.keywords.contains("account"),
                    "parsing-lexing-sets.entities.account-not-keyword"
                )
            }

            Step("transactions flavor keeps account and entity as idents") {
                let sets = EntryCompilerLexingSetsCache.pointer(
                    for: .transactions
                )

                try Expect.true(
                    sets.idents.contains("account"),
                    "parsing-lexing-sets.transactions.account-ident"
                )

                try Expect.true(
                    sets.idents.contains("entity"),
                    "parsing-lexing-sets.transactions.entity-ident"
                )
            }

            Step("entries flavor exposes entry keyword set") {
                let sets = EntryCompilerLexingSetsCache.pointer(
                    for: .entries
                )

                try Expect.true(
                    sets.keywords.contains("entry"),
                    "parsing-lexing-sets.entries.entry-keyword"
                )
            }
        }
    }
}
