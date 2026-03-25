import Foundation

public enum CompiledChartIndexError: Error, CustomStringConvertible, Sendable {
    case duplicateIdentifier(String)
    case duplicateSortKey(String)
    case duplicateReference(String)
    case missingParentKey(String, for: String) // (parentKey, childCode)

    public var description: String {
        switch self {
        case .duplicateIdentifier(let k): return "Duplicate identifier: \(k)"
        case .duplicateSortKey(let k):    return "Duplicate sort key: \(k)"
        case .duplicateReference(let k):  return "Duplicate reference: \(k)"
        case .missingParentKey(let p, let c): return "Missing parent key '\(p)' referenced by node '\(c)'"
        }
    }
}
