import Foundation
import TestFlows

@main
enum AccountingTestFlowTestingMain {
    static func main() async throws {
        if CommandLine.arguments.count == 4,
           CommandLine.arguments[1] == "--id-scanner-stdout-probe" {
            try IDScannerStdoutProbe.run(
                mode: CommandLine.arguments[2],
                root: URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
            )
            return
        }
        await TestFlowCLI.run(
            suite: AccountingTestFlowsSuite.self
        )
    }
}
