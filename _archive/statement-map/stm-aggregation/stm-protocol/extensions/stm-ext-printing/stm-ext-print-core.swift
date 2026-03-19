import Foundation

public extension StatementAggregating {
    @inline(__always)
    func fmt(_ d: Decimal) -> String {
        // change to your formatter if you prefer
        var v = d
        return NSDecimalString(&v, Locale(identifier: "nl_NL"))
    }

    func label(for part: [DimensionKey: DimensionValue]) -> String {
        if part.isEmpty { return "(total)" }
        var chunks: [String] = []
        // stable order
        for k in part.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let v = part[k] else { continue }
            switch v {
            case .text(let s):
                chunks.append("\(k.rawValue)=\(s)")
            case .entity(let e):
                chunks.append("\(k.rawValue)=\(e.identifier(displaying: .fullchain))")
            }
        }
        if chunks.isEmpty { return "(total)" }
        return chunks.joined(separator: ", ")
    }
}
