import Foundation

public enum CompilingAssertionError: Error, CustomStringConvertible {
    case unbalanced(id: Int?, delta: Decimal)

    public var description: String {
        switch self {
        case .unbalanced(let id, let d): 
            return "Entry \(id.map(String.init) ?? "<?>") not balanced (Δ=\(d))."
        }
    }
}
