import Accounting
import TestFlows

extension AccountingTestFlowsSuite {
    static var lspAccountingSurfaceFlow: TestFlow {
        TestFlow(
            "lsp-accounting-surface",
            tags: [
                "lsp",
                "lexer",
                "surface",
            ]
        ) {
            Step("LSP-used lexing flavors expose cached keyword sets") {
                let flavors: [(EntryCompilerLexingFlavor, String)] = [
                    (.settings, "settings"),
                    (.accounts, "accounts"),
                    (.entities, "entities"),
                    (.entries, "entries"),
                    (.transactions, "transactions"),
                    (.documents, "documents"),
                    (.fallback, "fallback"),
                ]

                for (flavor, label) in flavors {
                    let sets = EntryCompilerLexingSetsCache.pointer(
                        for: flavor
                    )

                    try Expect.notEmpty(
                        sets.keywords,
                        "lsp-accounting-surface.\(label).keywords"
                    )
                }
            }

            Step("LSP-sensitive file flavors are represented in Accounting") {
                let settings = EntryCompilerLexingSetsCache.pointer(
                    for: .settings
                )

                let accounts = EntryCompilerLexingSetsCache.pointer(
                    for: .accounts
                )

                let entities = EntryCompilerLexingSetsCache.pointer(
                    for: .entities
                )

                try Expect.true(
                    settings.keywords.contains("settings"),
                    "lsp-accounting-surface.settings.keyword"
                )

                try Expect.true(
                    accounts.keywords.contains("account"),
                    "lsp-accounting-surface.accounts.keyword"
                )

                try Expect.true(
                    entities.keywords.contains("entity"),
                    "lsp-accounting-surface.entities.keyword"
                )
            }
        }
    }
}
