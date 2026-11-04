import TestFlows

@main
enum AccountingTestFlowTestingMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: AccountingTestFlowsSuite.self
        )
    }
}
