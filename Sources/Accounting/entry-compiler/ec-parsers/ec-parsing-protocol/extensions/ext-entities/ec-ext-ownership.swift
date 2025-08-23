import Foundation

public extension EntryCompilerParsing {
    /// ownership { change { effective_date = <date>; percentage = <number> }* }
    /// Stored as metadata: ownership.<idx>.date / ownership.<idx>.pct
    @inlinable
    func parseOwnershipBlock(into meta: inout [String:String], tz: TimeZone = .current) -> Bool {
        guard current == .keyword("ownership") || current == .ident("ownership") else { return false }
        advance(); try? beginBlock()
        var idx = 0
        while current != .rBrace && current != .eof {
            guard current == .ident("change") || current == .keyword("change") else { break }
            advance(); try? beginBlock()
            var dateStr: String?
            var pct: String?
            while current != .rBrace && current != .eof {
                switch current {
                case .ident("effective_date"):
                    advance(); try? expect(.equals)
                    switch current {
                    case let .dateLiteral(text):
                        if let d = try? parseDateLiteral(text, in: tz) { dateStr = ISO8601DateFormatter().string(from: d) }
                        advance()
                    case .lBrace:
                        if let d = try? parseDateBlock(tz: tz) { dateStr = ISO8601DateFormatter().string(from: d) }
                    default: break
                    }
                case .ident("percentage"):
                    advance(); try? expect(.equals)
                    if case let .number(n) = current { pct = "\(n)"; advance() }
                default:
                    break
                }
            }
            _ = try? endBlock()
            if let d = dateStr { meta["ownership.\(idx).date"] = d }
            if let p = pct { meta["ownership.\(idx).pct"] = p }
            idx += 1
        }
        _ = try? endBlock()
        return true
    }
}
