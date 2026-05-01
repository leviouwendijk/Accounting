import Foundation
import Accounting
import AccountingParsers

func eclspFindProjectRoot(
    startingAt start: URL,
    hops: Int = 4
) -> URL? {
    let fm = FileManager.default
    var current = start.standardizedFileURL

    for _ in 0...hops {
        var isDir: ObjCBool = false

        let entries = current
            .appendingPathComponent("entries", isDirectory: true)
            .path

        if fm.fileExists(atPath: entries, isDirectory: &isDir),
           isDir.boolValue {
            return current
        }

        let config = current
            .appendingPathComponent("config", isDirectory: true)
            .path

        if fm.fileExists(atPath: config, isDirectory: &isDir),
           isDir.boolValue {
            return current
        }

        let parent = current.deletingLastPathComponent()
        if parent.path == current.path {
            break
        }

        current = parent
    }

    return nil
}

func eclspResolveProjectRoot(
    forDocumentURI uri: String,
    initializeRootURI: String?
) -> URL? {
    if let url = fileURL(from: uri) {
        let base = url.hasDirectoryPath ? url : url.deletingLastPathComponent()

        if let found = eclspFindProjectRoot(startingAt: base) {
            return found
        }
    }

    if let initializeRootURI,
       let url = fileURL(from: initializeRootURI) {
        let base = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        return eclspFindProjectRoot(startingAt: base) ?? base
    }

    return nil
}

func fileURL(
    from uri: String
) -> URL? {
    if uri.hasPrefix("file://") {
        return URL(string: uri)
    }

    if uri.hasPrefix("/") {
        return URL(fileURLWithPath: uri)
    }

    return nil
}

func inferFlavor(
    forDocumentURI uri: String
) -> EntryCompilerLexingFlavor {
    guard let url = fileURL(from: uri) else {
        return .fallback
    }

    let path = url.path

    if path.hasSuffix("/config/settings.ec") {
        return .settings
    }

    if path.contains("/config/accounts/") {
        return .accounts
    }

    if path.contains("/config/entities/") {
        return .entities
    }

    if path.contains("/transactions/") {
        return .transactions
    }

    if path.contains("/documents/") {
        return .documents
    }

    if path.contains("/entries/") {
        return .entries
    }

    return .fallback
}
