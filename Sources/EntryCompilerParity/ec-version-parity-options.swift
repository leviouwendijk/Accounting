import Terminal
import Foundation

struct ECVersionParityOptions: Sendable {
    var oldBinary: String = "ec-v1"
    var newBinary: String = "ec"
    var project: String = FileManager.default.currentDirectoryPath
    var output: String?
    var anchor: String = "2025-01-01"
    var yearAnchor: String = "2025"
    var context: Int = 4
    var only: Set<String> = []
    var showPassing: Bool = false
    var plain: Bool = false
    var writeArtifacts: Bool = true

    static func parse(
        _ arguments: [String]
    ) throws -> Self {
        var options = Self()
        var index = 0

        func value(
            after flag: String
        ) throws -> String {
            let valueIndex = index + 1

            guard valueIndex < arguments.count else {
                throw ECVersionParityError.missingValue(
                    flag
                )
            }

            return arguments[valueIndex]
        }

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--old":
                options.oldBinary = try value(
                    after: argument
                )
                index += 2

            case "--new":
                options.newBinary = try value(
                    after: argument
                )
                index += 2

            case "--project", "-p":
                options.project = try value(
                    after: argument
                )
                index += 2

            case "--out", "-o":
                options.output = try value(
                    after: argument
                )
                index += 2

            case "--anchor":
                options.anchor = try value(
                    after: argument
                )
                index += 2

            case "--year-anchor":
                options.yearAnchor = try value(
                    after: argument
                )
                index += 2

            case "--context":
                let raw = try value(
                    after: argument
                )

                guard let parsed = Int(raw), parsed >= 0 else {
                    throw ECVersionParityError.invalidInteger(
                        flag: argument,
                        value: raw
                    )
                }

                options.context = parsed
                index += 2

            case "--only":
                let raw = try value(
                    after: argument
                )

                options.only = Set(
                    raw
                        .split(separator: ",")
                        .map(String.init)
                        .filter { !$0.isEmpty }
                )

                index += 2

            case "--show-passing":
                options.showPassing = true
                index += 1

            case "--plain":
                options.plain = true
                index += 1

            case "--no-artifacts":
                options.writeArtifacts = false
                index += 1

            case "--help", "-h":
                Terminal.write(
                    Self.help + "\n"
                )
                Foundation.exit(0)

            default:
                throw ECVersionParityError.unknownArgument(
                    argument
                )
            }
        }

        return options
    }

    static let help = """
    ecvparity

    Usage:
        ecvparity [options]

    Options:
        --old <binary>            Old binary. Default: ec-v1
        --new <binary>            New binary. Default: ec
        --project, -p <path>      Accounting project dir. Default: current directory
        --out, -o <path>          Artifact output dir. Default: /tmp/ecvparity-<timestamp>
        --anchor <anchor>         Period anchor. Default: 2025-01-01
        --year-anchor <anchor>    Year anchor. Default: 2025
        --context <n>             Diff context lines. Default: 4
        --only <a,b,c>            Comma-separated case names
        --show-passing            Print passing case summaries
        --plain                   Disable ANSI color in rendered diffs
        --no-artifacts            Do not write stdout/stderr/diff files
    """
}

