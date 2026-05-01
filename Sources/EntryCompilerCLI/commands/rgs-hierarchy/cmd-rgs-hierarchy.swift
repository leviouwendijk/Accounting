import Accounting
import AccountingCompiler
import Arguments
import Foundation

enum RGSSideFilter: String, Sendable, ArgumentValue {
    case all
    case balance
    case profit

    func matches(
        _ node: RGSNode
    ) -> Bool {
        switch self {
        case .all:
            return true

        case .balance:
            return node.side == .balance

        case .profit:
            return node.side == .profitLoss
        }
    }
}

private enum RGSTreePrinter {
    static func printTree(
        nodes: [RGSNode],
        parentById: [Int: Int?],
        maxLevel: Int?
    ) {
        let nodeById = Dictionary(
            uniqueKeysWithValues: nodes.map { node in
                (
                    node.id,
                    node
                )
            }
        )

        var childrenByParentId: [Int: [RGSNode]] = [:]
        var roots: [RGSNode] = []

        for node in nodes {
            if let parentId = parentById[node.id] ?? nil,
               nodeById[parentId] != nil {
                childrenByParentId[parentId, default: []].append(
                    node
                )
            } else {
                roots.append(
                    node
                )
            }
        }

        func sort(
            _ nodes: inout [RGSNode]
        ) {
            nodes.sort { lhs, rhs in
                let lhsKey = lhs.xlsx?.sorting.key ?? lhs.codes.code
                let rhsKey = rhs.xlsx?.sorting.key ?? rhs.codes.code

                if lhsKey == rhsKey {
                    return lhs.codes.code < rhs.codes.code
                }

                return lhsKey < rhsKey
            }
        }

        func render(
            _ node: RGSNode
        ) {
            if let maxLevel,
               Int(node.level) > maxLevel {
                return
            }

            let indent = String(
                repeating: "  ",
                count: max(
                    0,
                    Int(node.level) - 1
                )
            )

            print("\(indent)\(node.codes.code) — \(node.labels.short)")

            var children = childrenByParentId[node.id] ?? []
            sort(
                &children
            )

            for child in children {
                render(
                    child
                )
            }
        }

        sort(
            &roots
        )

        for root in roots {
            render(
                root
            )
        }
    }
}

enum RGSHierarchyCommand: BoundArgumentCommand {
    static let name = "rgs-hierarchy"

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Opt("max-level")
        var maxLevel: Int?

        @Opt(
            "side",
            default: .all
        )
        var side: RGSSideFilter

        @Flag(
            "show-problems",
            default: true
        )
        var showProblems: Bool

        @Flag("verbose")
        var verbose: Bool

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

        let root = EntryCompilerProject.findRoot(
            startingAt: provided
        ) ?? provided

        let project = EntryCompilerProject(
            root: root
        )

        let settings = try EntryCompilerSettingsLoader.load(
            from: root
        )

        let diagnostics = try RGSHierarchyDiagnostics.run(
            project: project,
            settings: settings,
            sideFilter: { node in
                options.side.matches(
                    node
                )
            }
        )

        RGSTreePrinter.printTree(
            nodes: diagnostics.nodes,
            parentById: diagnostics.parentById,
            maxLevel: options.maxLevel
        )

        guard options.showProblems,
              !diagnostics.problems.isEmpty else {
            return
        }

        fputs("\n-- Problems --\n", stderr)

        for problem in diagnostics.problems.sorted(by: { lhs, rhs in
            lhs.description < rhs.description
        }) {
            fputs("  • \(problem.description)\n", stderr)
        }
    }
}
