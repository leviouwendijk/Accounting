import Accounting
import Foundation
import Arguments

public enum EntryCompilerIntegrityError: Error, CustomStringConvertible, Sendable {

    public enum IDKind: String, Codable, Sendable, ArgumentValue { 
        case transaction
        case entry 
    }

    public enum RefKind: String, Codable, Sendable, ArgumentValue { 
        case transactionRef 
        case entryRef 
    }

    /// Two or more files declare the same global integer id.
    case idCollision(kind: IDKind, id: Int, paths: [String])

    /// A reference points to a non-existent id.
    /// `contextPath` = file where the bad ref is found.
    case danglingReference(kind: RefKind, id: Int, contextPath: String)

    public var description: String {
        switch self {
        case let .idCollision(kind, id, paths):
            var s = "[ERROR] \(kind.rawValue.capitalized) ID collision: \(id)\n"
            for p in paths { s += "  - \(p)\n" }
            s += "Fix: reassign one file to a new id and update refs."
            return s

        case let .danglingReference(kind, id, contextPath):
            return """
            [ERROR] Dangling \(kind.rawValue) \(id)
              in: \(contextPath)
            Fix: create the referenced object or remove/replace the ref.
            """
        }
    }
}
