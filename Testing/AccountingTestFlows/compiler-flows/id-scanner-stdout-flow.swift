import Accounting
import AccountingCompiler
import Foundation
import TestFlows

// This probe runs in a child process: no process-wide fd redirection in the host
// or in a test runner that might execute other flows concurrently.
private enum IDScannerStdoutProbeError: Error {
    case unexpectedIDs
    case unexpectedMode(String)
}

enum IDScannerStdoutProbe {
    static func run(mode: String, root: URL) throws {
        let project = EntryCompilerProject(root: root)
        let settings = try ECModelFixtures.parseSettings()

        switch mode {
        case "control":
            // The general-purpose loader intentionally keeps its default warning.
            let entries = try EntryCompilerEntriesLoader.load(
                from: project,
                settings: settings,
                trace: false
            )
            guard entries.count == 2 else { throw IDScannerStdoutProbeError.unexpectedIDs }

        case "scanner":
            // Both scanner paths must be silent and preserve their ID semantics.
            let ids = try IDScanner.usedIDs(
                project: project,
                settings: settings,
                kind: .entry,
                allowCollisions: false
            )
            let next = try IDScanner.suggestNextEntryID(
                project: project,
                settings: settings,
                allowCollisions: false
            )
            guard ids == [41, 46], next == 47 else {
                throw IDScannerStdoutProbeError.unexpectedIDs
            }

        default:
            throw IDScannerStdoutProbeError.unexpectedMode(mode)
        }
    }
}

extension AccountingTestFlowsSuite {
    static var idScannerStdoutFlow: TestFlow {
        TestFlow("accounting-id-scanner-stdout", tags: ["accounting", "id", "stdout"]) {
            Step("ID lookup emits no terminal warnings despite placeholder entities") {
                let manager = FileManager.default
                let root = manager.temporaryDirectory.appendingPathComponent(
                    "accounting-id-scanner-stdout-\(UUID().uuidString)", isDirectory: true
                )
                let month = root.appendingPathComponent("entries/2026/2/4", isDirectory: true)
                try manager.createDirectory(at: month, withIntermediateDirectories: true)
                defer { try? manager.removeItem(at: root) }

                // The first entry has a real placeholder entity, exercising the
                // existing loader's warning; second establishes the expected next ID.
                try """
                entry {
                    id = 41
                    date = 2026-04-12
                    for placeholder(service) in (WOmzNodOdh) {
                        credit = 10.00
                    }
                }
                entry { id = 46 date = 2026-04-13 }
                """.write(
                    to: month.appendingPathComponent("main.ec"),
                    atomically: true,
                    encoding: .utf8
                )

                func capture(_ mode: String) throws -> (Int32, String, String) {
                    let process = Process()
                    process.executableURL = Bundle.main.executableURL
                        ?? URL(fileURLWithPath: CommandLine.arguments[0])
                    process.arguments = ["--id-scanner-stdout-probe", mode, root.path]
                    let stdout = Pipe()
                    let stderr = Pipe()
                    process.standardOutput = stdout
                    process.standardError = stderr
                    try process.run()
                    process.waitUntilExit()
                    return (
                        process.terminationStatus,
                        String(decoding: stdout.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self),
                        String(decoding: stderr.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                    )
                }

                let control = try capture("control")
                try Expect.equal(control.0, 0, "Control loader exits successfully: \(control.2)")
                try Expect.equal(
                    control.1.contains("! WARNING: Placeholder entities detected"),
                    true,
                    "Fixture actually triggers the default loader warning"
                )

                let scanner = try capture("scanner")
                try Expect.equal(scanner.0, 0, "ID scanner exits successfully: \(scanner.2)")
                try Expect.equal(scanner.1, "", "ID scanner must not emit to stdout")
                try Expect.equal(scanner.2, "", "ID scanner must not emit to stderr")
            }
        }
    }
}
