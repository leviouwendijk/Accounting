import Accounting
import Arguments
import Foundation
import Interfaces
import Milieu
import Terminal
import Writers

enum EntryCompilerIDKind: String, Sendable, ArgumentValue {
    case entry
    case transaction

    var idKind: Accounting.IDKind {
        switch self {
        case .entry:
            .entry

        case .transaction:
            .transaction
        }
    }
}


enum IDCommand: ArgumentCommand {
    static let name = "id"

    static let children: [ArgumentCommandType] = [
        Used.self,
        Next.self,
    ]

    struct Used: BoundArgumentCommand {
        static let name = "used"

        struct Options: ArgumentGroup {
            @Group("project")
            var project: ProjectOptions

            @Opt("kind", default: .entry)
            var kind: EntryCompilerIDKind

            @Flag("raw")
            var raw: Bool

            @Flag("verbose")
            var verbose: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let root = URL(
                fileURLWithPath: options.project.resolvedPath,
                isDirectory: true
            )

            let project = EntryCompilerProject(
                root: root
            )

            let settings = try EntryCompilerSettingsLoader.load(
                from: root
            )

            let reporter = CollisionReporter()

            let ids = try IDScanner.usedIDs(
                project: project,
                settings: settings,
                kind: options.kind.idKind,
                allowCollisions: true,
                verbose: options.verbose,
                onCollision: reporter.callback()
            )

            print("kind: \(options.kind.rawValue)")
            print("used count: \(ids.count)")

            if let first = ids.first,
               let last = ids.last {
                print("min..max: \(first)..\(last)")
            } else {
                print("min..max: —")
            }

            print("used: \(IDScanner.string(IDScanner.compressRuns(ids)))")

            let holes = IDScanner.gaps(
                between: ids
            )

            print(
                holes.isEmpty
                    ? "gaps: (none)"
                    : "gaps: \(IDScanner.string(holes))"
            )

            if options.raw,
               !ids.isEmpty {
                print("raw:  \(ids.map(String.init).joined(separator: ", "))")
            }
        }
    }

    struct Next: BoundArgumentCommand {
        static let name = "next"

        struct Options: ArgumentGroup {
            @Group("project")
            var project: ProjectOptions

            @Opt("kind", default: .entry)
            var kind: EntryCompilerIDKind

            @Flag("verbose")
            var verbose: Bool

            @Flag("stdout")
            var stdout: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let provided = URL(
                fileURLWithPath: options.project.resolvedPath,
                isDirectory: true
            )

            guard let root = EntryCompilerProject.findRoot(
                startingAt: provided
            ) else {
                throw EntryCompilerCLIError.validation(
                    "Could not locate project root starting at: \(provided.path)"
                )
            }

            let project = EntryCompilerProject(
                root: root
            )

            let settings = try EntryCompilerSettingsLoader.load(
                from: root
            )

            let reporter = CollisionReporter()

            let ids = try IDScanner.usedIDs(
                project: project,
                settings: settings,
                kind: options.kind.idKind,
                allowCollisions: true,
                verbose: options.verbose,
                onCollision: reporter.callback()
            )

            let latest = ids.max()

            let suggested: Int = {
                switch options.kind {
                case .entry:
                    return (
                        try? IDScanner.suggestNextEntryID(
                            project: project,
                            settings: settings
                        )
                    ) ?? ((latest ?? 0) + 1)

                case .transaction:
                    return (
                        try? IDScanner.suggestNextTransactionID(
                            project: project,
                            verbose: options.verbose
                        )
                    ) ?? ((latest ?? 0) + 1)
                }
            }()

            if options.stdout {
                print(suggested)
            } else {
                print("kind: \(options.kind.rawValue)")
                print("latest: \(latest.map(String.init) ?? "—")")
                print("suggested next: \(suggested)")
            }
        }
    }
}

// MARK: - RGS hierarchy


