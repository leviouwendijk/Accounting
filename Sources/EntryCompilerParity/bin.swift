import Difference
import Foundation
import Interfaces
import Terminal

@main
enum EntryCompilerVersionParityMain {
    static func main() async {
        do {
            let options = try ECVersionParityOptions.parse(
                Array(
                    CommandLine.arguments.dropFirst()
                )
            )

            let result = try await ECVersionParityRunner.run(
                options: options
            )

            Foundation.exit(
                result.failedCount == 0 ? 0 : 1
            )
        } catch {
            Terminal.write(
                "ecvparity failed: \(error)\n".ansi(
                    .red,
                    .bold
                ),
                to: .standardError
            )

            Foundation.exit(2)
        }
    }
}

struct ECVersionParityCase: Sendable {
    let name: String
    let oldArguments: [String]
    let newArguments: [String]

    init(
        _ name: String,
        _ arguments: [String]
    ) {
        self.name = name
        self.oldArguments = arguments
        self.newArguments = arguments
    }

    init(
        _ name: String,
        old oldArguments: [String],
        new newArguments: [String]
    ) {
        self.name = name
        self.oldArguments = oldArguments
        self.newArguments = newArguments
    }
}

struct ECVersionParityCommandOutput: Sendable {
    let binary: String
    let arguments: [String]
    let exitCode: Int?
    let stdout: String
    let stderr: String

    var commandLine: String {
        ([binary] + arguments)
            .map(shellQuote)
            .joined(separator: " ")
    }

    var exitCodeLabel: String {
        exitCode.map(String.init) ?? "-"
    }
}

struct ECVersionParityCaseResult: Sendable {
    let testCase: ECVersionParityCase
    let old: ECVersionParityCommandOutput
    let new: ECVersionParityCommandOutput
    let outputDirectory: URL?

    var statusChanged: Bool {
        old.exitCode != new.exitCode
    }

    var stdoutChanged: Bool {
        old.stdout != new.stdout
    }

    var stderrChanged: Bool {
        old.stderr != new.stderr
    }

    var failed: Bool {
        statusChanged || stdoutChanged || stderrChanged
    }
}

struct ECVersionParityRunResult: Sendable {
    let cases: [ECVersionParityCaseResult]

    var failedCount: Int {
        cases.filter(\.failed).count
    }

    var passedCount: Int {
        cases.count - failedCount
    }
}

enum ECVersionParityRunner {
    static func run(
        options: ECVersionParityOptions
    ) async throws -> ECVersionParityRunResult {
        let projectURL = URL(
            fileURLWithPath: options.project,
            isDirectory: true
        )

        let outputURL = try makeOutputDirectory(
            options: options
        )

        let cases = allCases(
            anchor: options.anchor,
            yearAnchor: options.yearAnchor
        )
        .filter { testCase in
            options.only.isEmpty || options.only.contains(
                testCase.name
            )
        }

        printHeader(
            options: options,
            projectURL: projectURL,
            outputURL: outputURL
        )

        var results: [ECVersionParityCaseResult] = []

        for testCase in cases {
            let result = try await runCase(
                testCase,
                options: options,
                projectURL: projectURL,
                outputURL: outputURL
            )

            results.append(
                result
            )

            render(
                result,
                options: options
            )
        }

        let runResult = ECVersionParityRunResult(
            cases: results
        )

        printSummary(
            runResult,
            outputURL: outputURL
        )

        return runResult
    }

    private static func runCase(
        _ testCase: ECVersionParityCase,
        options: ECVersionParityOptions,
        projectURL: URL,
        outputURL: URL?
    ) async throws -> ECVersionParityCaseResult {
        let old = try await runCommand(
            binary: options.oldBinary,
            arguments: testCase.oldArguments,
            cwd: projectURL
        )

        let new = try await runCommand(
            binary: options.newBinary,
            arguments: testCase.newArguments,
            cwd: projectURL
        )

        let caseOutputURL: URL?

        if let outputURL,
           options.writeArtifacts {
            let url = outputURL.appendingPathComponent(
                testCase.name,
                isDirectory: true
            )

            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true
            )

            caseOutputURL = url

            try writeArtifacts(
                testCase: testCase,
                old: old,
                new: new,
                outputURL: url,
                context: options.context
            )
        } else {
            caseOutputURL = nil
        }

        return .init(
            testCase: testCase,
            old: old,
            new: new,
            outputDirectory: caseOutputURL
        )
    }

    private static func runCommand(
        binary: String,
        arguments: [String],
        cwd: URL
    ) async throws -> ECVersionParityCommandOutput {
        var shellOptions = Shell.Options()
        shellOptions.cwd = cwd
        shellOptions.expectedExitCodes = Set(
            0...255
        )
        shellOptions.teeToStdout = false
        shellOptions.teeToStderr = false

        let command = ([binary] + arguments)
            .map(shellQuote)
            .joined(separator: " ")

        let result = try await Shell(.path("/bin/zsh")).run(
            "/bin/zsh",
            [
                "-lc",
                command,
            ],
            options: shellOptions
        )

        return .init(
            binary: binary,
            arguments: arguments,
            exitCode: result.exitCode,
            stdout: result.stdoutText(),
            stderr: result.stderrText()
        )
    }

    private static func render(
        _ result: ECVersionParityCaseResult,
        options: ECVersionParityOptions
    ) {
        guard result.failed || options.showPassing else {
            return
        }

        let title = result.failed
            ? "fail \(result.testCase.name)"
            : "pass \(result.testCase.name)"

        Terminal.write(
            "\n\(title)\n".ansi(
                result.failed ? .red : .green,
                .bold
            )
        )

        Terminal.write(
            "  old     \(result.old.commandLine)\n"
        )
        Terminal.write(
            "  new     \(result.new.commandLine)\n"
        )

        if result.statusChanged {
            Terminal.write(
                "  status  old=\(result.old.exitCodeLabel) new=\(result.new.exitCodeLabel)\n".ansi(
                    .yellow
                )
            )
        } else if options.showPassing {
            Terminal.write(
                "  status  \(result.old.exitCodeLabel)\n"
            )
        }

        if let outputDirectory = result.outputDirectory {
            Terminal.write(
                "  files   \(outputDirectory.path)\n".ansi(
                    .brightBlack
                )
            )
        }

        if result.stdoutChanged {
            renderDifference(
                old: result.old.stdout,
                new: result.new.stdout,
                oldName: "\(result.testCase.name)/old.stdout",
                newName: "\(result.testCase.name)/new.stdout",
                title: "stdout",
                options: options
            )
        } else if options.showPassing {
            Terminal.write(
                "  stdout  ok\n".ansi(
                    .green
                )
            )
        }

        if result.stderrChanged {
            renderDifference(
                old: result.old.stderr,
                new: result.new.stderr,
                oldName: "\(result.testCase.name)/old.stderr",
                newName: "\(result.testCase.name)/new.stderr",
                title: "stderr",
                options: options
            )
        } else if options.showPassing {
            Terminal.write(
                "  stderr  ok\n".ansi(
                    .green
                )
            )
        }
    }

    private static func renderDifference(
        old: String,
        new: String,
        oldName: String,
        newName: String,
        title: String,
        options: ECVersionParityOptions
    ) {
        let difference = TextDiffer.diff(
            old: old,
            new: new,
            oldName: oldName,
            newName: newName
        )

        let renderOptions = DifferenceRenderOptions(
            showHeader: true,
            showUnchangedLines: false,
            contextLineCount: options.context
        )

        let rendered: String

        if options.plain {
            rendered = DifferenceRenderer.render(
                difference,
                options: renderOptions
            )
        } else {
            rendered = TerminalDifferenceRenderer.render(
                difference,
                options: .init(
                    base: renderOptions
                )
            )
        }

        Terminal.write(
            "\n  \(title) diff\n".ansi(
                .bold
            )
        )

        Terminal.write(
            rendered + "\n"
        )
    }

    private static func writeArtifacts(
        testCase: ECVersionParityCase,
        old: ECVersionParityCommandOutput,
        new: ECVersionParityCommandOutput,
        outputURL: URL,
        context: Int
    ) throws {
        try write(
            old.stdout,
            to: outputURL.appendingPathComponent(
                "old.stdout.txt"
            )
        )

        try write(
            old.stderr,
            to: outputURL.appendingPathComponent(
                "old.stderr.txt"
            )
        )

        try write(
            new.stdout,
            to: outputURL.appendingPathComponent(
                "new.stdout.txt"
            )
        )

        try write(
            new.stderr,
            to: outputURL.appendingPathComponent(
                "new.stderr.txt"
            )
        )

        try write(
            old.commandLine + "\n",
            to: outputURL.appendingPathComponent(
                "old.command.txt"
            )
        )

        try write(
            new.commandLine + "\n",
            to: outputURL.appendingPathComponent(
                "new.command.txt"
            )
        )

        if old.stdout != new.stdout {
            try writePlainDiff(
                old: old.stdout,
                new: new.stdout,
                oldName: "\(testCase.name)/old.stdout",
                newName: "\(testCase.name)/new.stdout",
                context: context,
                to: outputURL.appendingPathComponent(
                    "stdout.diff.txt"
                )
            )
        }

        if old.stderr != new.stderr {
            try writePlainDiff(
                old: old.stderr,
                new: new.stderr,
                oldName: "\(testCase.name)/old.stderr",
                newName: "\(testCase.name)/new.stderr",
                context: context,
                to: outputURL.appendingPathComponent(
                    "stderr.diff.txt"
                )
            )
        }

        if old.exitCode != new.exitCode {
            try write(
                "old=\(old.exitCodeLabel)\nnew=\(new.exitCodeLabel)\n",
                to: outputURL.appendingPathComponent(
                    "status.diff.txt"
                )
            )
        }
    }

    private static func writePlainDiff(
        old: String,
        new: String,
        oldName: String,
        newName: String,
        context: Int,
        to url: URL
    ) throws {
        let difference = TextDiffer.diff(
            old: old,
            new: new,
            oldName: oldName,
            newName: newName
        )

        let rendered = DifferenceRenderer.render(
            difference,
            options: .init(
                showHeader: true,
                showUnchangedLines: false,
                contextLineCount: context
            )
        )

        try write(
            rendered + "\n",
            to: url
        )
    }

    private static func write(
        _ text: String,
        to url: URL
    ) throws {
        try text.write(
            to: url,
            atomically: true,
            encoding: .utf8
        )
    }

    private static func allCases(
        anchor: String,
        yearAnchor: String
    ) -> [ECVersionParityCase] {
        [
            .init(
                "compile",
                [
                    "compile",
                ]
            ),

            .init(
                "period-quarter",
                [
                    "period",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "compile-period-quarter",
                [
                    "compile",
                    "period",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "period-quarter-presentation-explicit",
                [
                    "period",
                    "quarter",
                    "--anchor",
                    anchor,
                    "--caption",
                    "label",
                    "--detail",
                    "standard",
                ]
            ),
            .init(
                "period-quarter-concise",
                [
                    "period",
                    "quarter",
                    "--anchor",
                    anchor,
                    "--detail",
                    "concise",
                ]
            ),

            .init(
                "compile-period-quarter-presentation-explicit",
                [
                    "compile",
                    "period",
                    "quarter",
                    "--anchor",
                    anchor,
                    "--caption",
                    "label",
                    "--detail",
                    "standard",
                ]
            ),

            .init(
                "equity-quarter",
                [
                    "equity",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "compile-equity-quarter",
                [
                    "compile",
                    "equity",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "vat-overview-quarter",
                [
                    "vat",
                    "overview",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "vat-audit-quarter",
                [
                    "vat",
                    "audit",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "vat-status-quarter",
                [
                    "vat",
                    "status",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "assets-overview-quarter",
                [
                    "assets",
                    "overview",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "assets-acquired-quarter",
                [
                    "assets",
                    "acquired",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "assets-validate",
                [
                    "assets",
                    "validate",
                ]
            ),

            .init(
                "assets-shares-year",
                [
                    "assets",
                    "shares",
                    "year",
                    "--anchor",
                    yearAnchor,
                ]
            ),

            .init(
                "cost-breakdown-quarter",
                [
                    "cost",
                    "breakdown",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),

            .init(
                "id-used-entry",
                [
                    "id",
                    "used",
                ]
            ),

            .init(
                "id-used-transaction",
                [
                    "id",
                    "used",
                    "--kind",
                    "transaction",
                ]
            ),

            .init(
                "id-next-entry",
                [
                    "id",
                    "next",
                ]
            ),

            .init(
                "id-next-transaction",
                [
                    "id",
                    "next",
                    "--kind",
                    "transaction",
                ]
            ),

            .init(
                "depreciation-monthly",
                [
                    "depreciation",
                ]
            ),

            .init(
                "depreciation-periods",
                [
                    "depreciation",
                    "--detail",
                    "periods",
                ]
            ),

            .init(
                "kia-audit-year",
                [
                    "kia",
                    "audit",
                    "--year",
                    yearAnchor,
                ]
            ),

            .init(
                "kia-audit-year-diagnostics",
                [
                    "kia",
                    "audit",
                    "--year",
                    yearAnchor,
                    "--diagnostics",
                ]
            ),

            .init(
                "rgs-hierarchy-balance-l2",
                [
                    "rgs-hierarchy",
                    "--side",
                    "balance",
                    "--max-level",
                    "2",
                ]
            ),

            .init(
                "rgs-hierarchy-profit-l2",
                [
                    "rgs-hierarchy",
                    "--side",
                    "profit",
                    "--max-level",
                    "2",
                ]
            ),

            .init(
                "meta-audit-year",
                [
                    "meta",
                    "audit",
                    "year",
                    "--anchor",
                    yearAnchor,
                ]
            ),

            .init(
                "meta-audit-quarter",
                [
                    "meta",
                    "audit",
                    "quarter",
                    "--anchor",
                    anchor,
                ]
            ),
        ]
    }

    private static func makeOutputDirectory(
        options: ECVersionParityOptions
    ) throws -> URL? {
        guard options.writeArtifacts else {
            return nil
        }

        let outputURL: URL

        if let output = options.output {
            outputURL = URL(
                fileURLWithPath: output,
                isDirectory: true
            )
        } else {
            outputURL = URL(
                fileURLWithPath: "/tmp/ecvparity-\(timestamp())",
                isDirectory: true
            )
        }

        try FileManager.default.createDirectory(
            at: outputURL,
            withIntermediateDirectories: true
        )

        return outputURL
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = .current

        return formatter.string(
            from: Date()
        )
    }

    private static func printHeader(
        options: ECVersionParityOptions,
        projectURL: URL,
        outputURL: URL?
    ) {
        Terminal.write(
            "EC version parity\n".ansi(
                .bold,
                .brightCyan
            )
        )

        Terminal.write(
            """
              old          \(options.oldBinary)
              new          \(options.newBinary)
              project      \(projectURL.path)
              anchor       \(options.anchor)
              year anchor  \(options.yearAnchor)
              output       \(outputURL?.path ?? "-")

            """
        )
    }

    private static func printSummary(
        _ result: ECVersionParityRunResult,
        outputURL: URL?
    ) {
        let summary = """
        Summary
        ───────
          cases    \(result.cases.count)
          passed   \(result.passedCount)
          failed   \(result.failedCount)
          output   \(outputURL?.path ?? "-")

        """

        Terminal.write(
            summary.ansi(
                result.failedCount == 0 ? .green : .red,
                .bold
            )
        )
    }
}

func shellQuote(
    _ value: String
) -> String {
    if value.isEmpty {
        return "''"
    }

    if value.rangeOfCharacter(
        from: .whitespacesAndNewlines
    ) == nil,
       !value.contains("'"),
       !value.contains("\"") {
        return value
    }

    return "'"
        + value.replacingOccurrences(
            of: "'",
            with: "'\"'\"'"
        )
        + "'"
}
