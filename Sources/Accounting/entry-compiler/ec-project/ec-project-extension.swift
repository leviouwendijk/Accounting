import Foundation

extension EntryCompilerProject {
    public enum ComponentType: Sendable {
        case file
        case directory

        public var path_extension: String {
            switch self {
            case .directory:
                return ""
            case .file:
                return ".ec"
            }
        }

        public var is_directory: Bool {
            switch self {
            case .directory:
                return true
            case .file:
                return false
            }
        }
    }

    public protocol Specification: Sendable {
        var type: ComponentType { get }
        var path_element: String { get }
    }
}
