import Foundation
import Position

public enum InferenceError: Error, CustomStringConvertible, Sendable {
    case missingEntityClass(alias: String, filePathHint: String, location: Position)
    case missingEntityFamily(alias: String, filePathHint: String, location: Position)

    public var description: String {
        switch self {
        case let .missingEntityClass(alias, hint, loc):
            return """
            Cannot infer entity class for alias '\(alias)' at \(loc).
            Expected to infer it from file path (e.g., \(hint)).
            """
        case let .missingEntityFamily(alias, hint, loc):
            return """
            Cannot infer entity family for alias '\(alias)' at \(loc).
            Expected to infer it from file path (e.g., \(hint)).
            """
        }
    }
}

@inlinable
public func _entityPathHint(fileURL: URL?, inferredClass: String?, inferredFamily: String?) -> String {
    if let cls = inferredClass, inferredFamily == nil { return "config/entities/\(cls)/<family>.ec" }
    if inferredClass == nil, let fam = inferredFamily { return "config/entities/<class>/\(fam).ec" }
    return "config/entities/<class>/<family>.ec"
}
