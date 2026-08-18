import TestFlows

enum AccountingTestFlowsSuite: TestFlowRegistry {
    static let title = "Accounting test flows"

    static let flows: [TestFlow] = [
        argumentSurfaceFlow,
        compilerProjectModelFlow,
        lspAccountingSurfaceFlow,
        parsingLexingSetsFlow,

        entryGrammarFlow,
        vatGrammarFlow,
        entityGrammarFlow,
        transactionGrammarFlow,
        entityStoreResolutionFlow,
        transactionStoreInvariantFlow,

        entryResolutionFlow,
        rgsIndexFlow,
        canonicalRootsFlow,
        compilerFixtureFlow,

        entryCoreFlow,
    ]
}
