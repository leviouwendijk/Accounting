import Foundation

public struct EntryCompilerProject: Sendable {
    public let root: URL
    public init(root: URL) { self.root = root }

    public enum Base: String, Sendable {
        case config
        case entries
        case statements
        case documents
        case transactions
        case test
    }

    public func url(_ base: Base) -> URL {
        return root.appendingPathComponent(base.rawValue, isDirectory: true)

        // switch base {
        // case .config:
        //     return root.appendingPathComponent("config", isDirectory: true)
        // case .entries:    
        //     return root.appendingPathComponent("entries", isDirectory: true)
        // case .statements: 
        //     return root.appendingPathComponent("statements", isDirectory: true)
        // case .documents: 
        //     return root.appendingPathComponent("documents", isDirectory: true)
        // case .transactions: 
        //     return root.appendingPathComponent("transactions", isDirectory: true)
        // case .test:
        //     return root.appendingPathComponent("test", isDirectory: true)
        // }
    }

    public enum Sub: String, Specification {
        case accounts
        case entities
        case resources
        case aggregation
        case settings 
        // case aggregation = "aggregation.ec"
        // case settings = "settings.ec"

        public var type: ComponentType {
            switch self {
            case    .accounts,
            	    .entities,
            	    .resources:
                return .directory

            case .aggregation,
                    .settings:
                return .file
            }
        }

        public var path_element: String {
            return self.rawValue + self.type.path_extension
        }
    }

    public func url(_ base: Base,_ sub: Sub) -> URL {
        var dir = self.url(base)

        dir = dir.appendingPathComponent(sub.path_element, isDirectory: sub.type.is_directory)
        
        // switch sub {
        //     case .accounts,
        //     	.entities,
        //     	.resources:
        //         dir = dir.appendingPathComponent(sub.rawValue, isDirectory: true)
        //     case .aggregation:
        //         dir = dir.appendingPathComponent(sub.rawValue, isDirectory: false)
        //     case .settings:
        //         dir = dir.appendingPathComponent(sub.rawValue, isDirectory: false)
        // }
        return dir
    }

    public func resource(finding component: String, version: ChartVersion) -> URL {
        var dir = url(.config, .resources)
        dir = dir.appendingPathComponent(component, isDirectory: true)

        let filename = version.filename(
            version: true,
            separator: "_",
            ext: .json
        )
        return dir.appendingPathComponent(filename, isDirectory: false)
    }

    public func statements(_ base: Base = .statements) -> URL {
        return url(base)
    }
}

// include subpaths?
// config/resources/rgs/v3_8.json -> source of RGSNode objects array
