import Foundation

public extension StatementAggregating {
    @inline(__always)
    func prettyDim(_ k: DimensionKey, _ v: DimensionValue) -> (String,String) {
        switch v {
        case .text(let s): return (k.rawValue, s)
        case .entity(let e): return (k.rawValue, e.identifier(displaying: .fullchain))
        }
    }
}
