import Foundation
import Workspace

public enum EntryCompilerProjectAccessError: Error, Sendable {
    case outsideProject(URL)
}

public extension EntryCompilerProject {
    /// Authorize one project-relative path. A successful layout match is never
    /// treated as a Workspace grant.
    @discardableResult
    func require(
        _ target: URL,
        capability: WorkspaceCapability
    ) throws -> WorkspaceAuthorization? {
        guard let context = workspaceContext else { return nil }

        let base = root.standardizedFileURL.path
        let path = target.standardizedFileURL.path
        guard path == base || path.hasPrefix(base + "/") else {
            throw EntryCompilerProjectAccessError.outsideProject(target)
        }

        // Require both the presented path and its resolved filesystem target.
        // A symlink inside the project cannot expand a .read/.scan grant or
        // redirect a read to a file outside the project root.
        let lexical = path == base ? "." : String(path.dropFirst(base.count + 1))
        _ = try context.authorize(lexical, capability: capability)

        let resolvedBase = root.resolvingSymlinksInPath().standardizedFileURL.path
        let resolvedPath = target.resolvingSymlinksInPath().standardizedFileURL.path
        guard resolvedPath == resolvedBase || resolvedPath.hasPrefix(resolvedBase + "/") else {
            throw EntryCompilerProjectAccessError.outsideProject(target)
        }
        let canonical = resolvedPath == resolvedBase
            ? "."
            : String(resolvedPath.dropFirst(resolvedBase.count + 1))
        return try context.authorize(canonical, capability: capability)
    }

    /// Authorize the scan before listing and authorize each file for read
    /// before returning it. Never silently fall back to trusted IO on denial.
    func ecFileURLs(at directory: URL) throws -> [URL] {
        try require(directory, capability: .scan)
        let files = ecFiles(at: directory)
        return try files.map { url in
            try require(url, capability: .read)?.authorizedPath.absoluteURL ?? url
        }
    }

    func readECSource(at url: URL) throws -> String {
        let authorization = try require(url, capability: .read)
        if let authorization, let context = workspaceContext {
            try context.requireCurrent(authorization)
        }
        return try readECSourceUnchecked(
            at: authorization?.authorizedPath.absoluteURL ?? url
        )
    }

    func readData(at url: URL) throws -> Data {
        let authorization = try require(url, capability: .read)
        if let authorization, let context = workspaceContext {
            try context.requireCurrent(authorization)
        }
        return try Data(contentsOf: authorization?.authorizedPath.absoluteURL ?? url)
    }
}
