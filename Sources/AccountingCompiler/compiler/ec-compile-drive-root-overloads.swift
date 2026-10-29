import Foundation

/// Compatibility entrypoints. Workspace-aware callers supply an
/// EntryCompilerProject(workspace:) instead of an ambient root URL.
public extension EntryCompileDriver {
    static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = .init(),
        verbose: Bool = false,
        placeholderWarnings: PlaceholderWarningMode = .summary
    ) throws -> Result {
        try compile(
            project: EntryCompilerProject(root: projectRoot),
            setting: setting,
            verbose: verbose,
            placeholderWarnings: placeholderWarnings
        )
    }

    static func compile(
        projectRoot: URL,
        setting: CompileDriveSetting = .init(),
        verbose: Bool = false,
        placeholderWarnings: PlaceholderWarningMode = .summary
    ) async throws -> Result {
        try await compile(
            project: EntryCompilerProject(root: projectRoot),
            setting: setting,
            verbose: verbose,
            placeholderWarnings: placeholderWarnings
        )
    }
}
