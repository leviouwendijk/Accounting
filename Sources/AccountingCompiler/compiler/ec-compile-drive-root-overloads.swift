import Foundation

/// Compatibility entrypoints. Workspace-aware callers supply an
/// EntryCompilerProject(workspace:) instead of an ambient root URL.
public extension EntryCompileDriver {
    static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = .init(),
        verbose: Bool = false
    ) throws -> Result {
        try compile(
            project: EntryCompilerProject(root: projectRoot),
            setting: setting,
            verbose: verbose
        )
    }

    static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = .init(),
        verbose: Bool = false
    ) async throws -> Result {
        try await compile(
            project: EntryCompilerProject(root: projectRoot),
            setting: setting,
            verbose: verbose
        )
    }
}
