import Accounting
import Foundation

public enum RGSHierarchyDiagnostics {
    public struct Output: Sendable {
        public let nodes: [RGSNode]
        public let parentById: [Int:Int?]
        public let problems: [RGSIdentifierHierarchy.Problem]

        public init(
            nodes: [RGSNode],
            parentById: [Int:Int?],
            problems: [RGSIdentifierHierarchy.Problem]
        ) {
            self.nodes = nodes
            self.parentById = parentById
            self.problems = problems
        }
    }

    /// Load the compiled RGS chart declared in settings.ec, then build the identifier hierarchy.
    public static func run(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        sideFilter: ((RGSNode) -> Bool)? = nil
    ) throws -> Output {
        let store = try AccountStoreLoader.load(
            from: project,
            settings: settings,
            verbose: false
        )

        var nodes = Array(store.byCode.values)
        if let f = sideFilter {
            nodes.removeAll { !f($0) }
        }

        let result = RGSIdentifierHierarchy.build(from: nodes)

        return .init(
            nodes: nodes,
            parentById: result.parentById,
            problems: result.problems
        )
    }

    public static func render(
        _ output: Output,
        title: String = "RGS hierarchy diagnostics",
        limit: Int? = nil
    ) -> String {
        var lines: [String] = []

        lines.append(title)
        lines.append(String(repeating: "─", count: title.count))
        lines.append("nodes: \(output.nodes.count)")
        lines.append("problems: \(output.problems.count)")

        let noParentCount = output.problems.reduce(into: 0) { acc, problem in
            if case .noParent = problem.kind {
                acc += 1
            }
        }

        let multipleParentsCount = output.problems.reduce(into: 0) { acc, problem in
            if case .multipleParents = problem.kind {
                acc += 1
            }
        }

        lines.append("no-parent: \(noParentCount)")
        lines.append("multiple-parents: \(multipleParentsCount)")

        guard !output.problems.isEmpty else {
            lines.append("")
            lines.append("(no hierarchy issues)")
            return lines.joined(separator: "\n")
        }

        let sortedProblems = output.problems.sorted {
            if $0.childCode != $1.childCode {
                return $0.childCode < $1.childCode
            }
            return $0.childId < $1.childId
        }

        let shownProblems: ArraySlice<RGSIdentifierHierarchy.Problem>
        if let limit {
            shownProblems = sortedProblems.prefix(limit)
        } else {
            shownProblems = sortedProblems[...]
        }

        lines.append("")
        lines.append("problems")
        lines.append("────────")

        for problem in shownProblems {
            switch problem.kind {
            case .noParent(let level):
                lines.append(
                    "- [no-parent] code=\(problem.childCode) id=\(problem.childId) childLevel=\(problem.childLevel) wantedParentLevel=\(level)"
                )

            case .multipleParents(let level, let candidates):
                lines.append(
                    "- [multiple-parents] code=\(problem.childCode) id=\(problem.childId) childLevel=\(problem.childLevel) wantedParentLevel=\(level) candidates=\(candidates.joined(separator: "\""))"
                )
            }
        }

        if let limit, sortedProblems.count > limit {
            lines.append("")
            lines.append("… truncated \(sortedProblems.count - limit) additional problem(s)")
        }

        return lines.joined(separator: "\n")
    }

    public static func print(
        _ output: Output,
        title: String = "RGS hierarchy diagnostics",
        limit: Int? = nil
    ) {
        Swift.print(
            render(
                output,
                title: title,
                limit: limit
            )
        )
    }
}

// public enum RGSHierarchyDiagnostics {
//     public struct Output: Sendable {
//         public let nodes: [RGSNode]
//         public let parentById: [Int:Int?]
//         public let problems: [RGSIdentifierHierarchy.Problem]
//     }

//     /// Load the compiled RGS chart declared in settings.ec, then build the identifier hierarchy.
//     public static func run(
//         project: EntryCompilerProject,
//         settings: EntryCompilerSettings,
//         sideFilter: ((RGSNode) -> Bool)? = nil
//     ) throws -> Output {
//         let store = try AccountStoreLoader.load(from: project, settings: settings, verbose: false) // prefers compiled chart json
//         var nodes = Array(store.byCode.values)
//         if let f = sideFilter { nodes.removeAll { !f($0) } }
//         let result = RGSIdentifierHierarchy.build(from: nodes)
//         return .init(nodes: nodes, parentById: result.parentById, problems: result.problems)
//     }
// }
