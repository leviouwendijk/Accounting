import Foundation

public struct EntryCompilerProject: Sendable {
    public let root: URL
    public init(root: URL) { self.root = root }

    public enum Base: String, Sendable {
        case config, entries, statements, test
    }

    public func url(_ base: Base) -> URL {
        switch base {
        case .config:     return root.appendingPathComponent("config", isDirectory: true)
        case .entries:    return root.appendingPathComponent("entries", isDirectory: true)
        case .statements: return root.appendingPathComponent("statements", isDirectory: true)
        case .test:       return root.appendingPathComponent("test", isDirectory: true)
        }
    }
}
