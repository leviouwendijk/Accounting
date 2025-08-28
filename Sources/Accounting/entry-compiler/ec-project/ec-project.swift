import Foundation

public struct EntryCompilerProject: Sendable {
    public let root: URL
    public init(root: URL) { self.root = root }

    public enum Base: String, Sendable {
        case config, entries, statements, transactions, test
    }

    public func url(_ base: Base) -> URL {
        switch base {
        case .config:
            return root.appendingPathComponent("config", isDirectory: true)
        case .entries:    
            return root.appendingPathComponent("entries", isDirectory: true)
        case .statements: 
            return root.appendingPathComponent("statements", isDirectory: true)
        case .transactions: 
            return root.appendingPathComponent("transactions", isDirectory: true)
        case .test:
            return root.appendingPathComponent("test", isDirectory: true)
        }
    }

    public enum Sub: String, Sendable {
        case accounts
        case entities
        case resources
        case aggregation = "aggregation.ec"
        case settings = "settings.ec"
    }

    public func url(_ base: Base,_ sub: Sub) -> URL {
        var dir = self.url(base)
        
        switch sub {
            case .accounts:
                dir = dir.appendingPathComponent(sub.rawValue, isDirectory: true)
            case .entities:
                dir = dir.appendingPathComponent(sub.rawValue, isDirectory: true)
            case .resources:
                dir = dir.appendingPathComponent(sub.rawValue, isDirectory: true)
            case .aggregation:
                dir = dir.appendingPathComponent(sub.rawValue, isDirectory: false)
            case .settings:
                dir = dir.appendingPathComponent(sub.rawValue, isDirectory: false)
        }
        return dir
    }

    public func rgs(version: ChartVersion) -> URL {
        let dir = url(.config, .resources)

        let filename = version.filename(
            version: true,
            separator: "_",
            ext: .json
        )
        return dir.appendingPathComponent(filename, isDirectory: false)
    }
}

// include subpaths?
// config/resources/rgs/v3_8.json -> source of RGSNode objects array
