import Foundation

public enum RGSHierarchyDiagnostics {
    public struct Output: Sendable {
        public let nodes: [RGSNode]
        public let parentById: [Int:Int?]
        public let problems: [RGSIdentifierHierarchy.Problem]
    }

    /// Load the compiled RGS chart declared in settings.ec, then build the identifier hierarchy.
    public static func run(
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        sideFilter: ((RGSNode) -> Bool)? = nil
    ) throws -> Output {
        let store = try AccountStoreLoader.load(from: project, settings: settings, verbose: false) // prefers compiled chart json
        var nodes = Array(store.byCode.values)
        if let f = sideFilter { nodes.removeAll { !f($0) } }
        let result = RGSIdentifierHierarchy.build(from: nodes)
        return .init(nodes: nodes, parentById: result.parentById, problems: result.problems)
    }
}

