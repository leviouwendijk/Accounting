import TestFlows

enum AccountingTestFlowsSuite: TestFlowRegistry {
    static let title = "Accounting long-running test flows"

    static let flows: [TestFlow] = [
        periodConservationFlow,
        directAssemblerNetIncomeFlow,
        exampleDepreciationWriterFlow,
        exampleVATIntegrationFlow,
        exampleDepreciationIntegrationFlow,
        nativeResolvedOutputIntegrationFlow,
    ]
}
