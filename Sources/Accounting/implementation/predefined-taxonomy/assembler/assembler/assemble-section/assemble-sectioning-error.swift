import Foundation

public enum SectioningError: LocalizedError, Sendable {
    case missingIndex
    case missingSortKey(id: Int)
    case nonBalanceNode(id: Int)
    case invalidBoundary(letter: String)
    case sectionRootNotFound(letter: String)

    public var errorDescription: String? {
        switch self {
        case .missingIndex:
            return "Sectioning: Compiled chart is missing an index."
        case .missingSortKey(let id):
            return "Sectioning: No sorting key for node id \(id)."
        case .nonBalanceNode(let id):
            return "Sectioning: Expected balance-node, got non-balance id \(id)."
        case .invalidBoundary(let letter):
            return "Sectioning: Invalid alphabetical boundary '\(letter)'."
        case .sectionRootNotFound(let letter):
            return "Sectioning: No section root for '\(letter)'."
        }
    }
}
