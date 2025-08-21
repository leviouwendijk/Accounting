import Foundation

public extension EntryCompilerParsing {
    // ---- Generic segment readers
    @inline(__always)
    func readFlatSegments() -> [String] {
        var segs: [String] = []
        while true {
            switch current {
            case let .ident(s): segs.append(s); advance()
            case let .number(n): segs.append("\(n)"); advance()
            case let .keyword(k) where k == "inventory": segs.append(k); advance()
            default: return segs
            }
            if current == .dot || current == .arrow { advance(); continue }
            return segs
        }
    }

    func readSegmentsUntilRPar(allowAllAsAlias: Bool = false) throws -> (String, [String]) {
        var segs: [String] = []
        while current != .rPar && current != .eof {
            switch current {
            case let .ident(s): segs.append(s); advance()
            case let .number(n): segs.append("\(n)"); advance()
            case .keyword("inventory"): segs.append("inventory"); advance()
            default:
                // don’t swallow unknown tokens; exit so the caller can fail cleanly
                break
            }
            if current == .arrow || current == .dot { advance(); continue }
            // stop if we hit something that isn’t a segment or separator
            if current != .ident(""), current != .number(0), current != .keyword("inventory") { break }
        }
        try expect(.rPar)
        guard !segs.isEmpty else { throw ParserError.unexpectedToken(current, expected: "non-empty path", at: loc()) }
        if allowAllAsAlias { return (segs.first ?? "", segs) }
        var copy = segs; let domain = copy.removeFirst(); return (domain, copy)
    }
}
