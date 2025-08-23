import Foundation

public extension EntryCompilerParsing {
    /// domain <ident>  → metadata["domain"] = value
    @inlinable
    func parseDomainDirective(into meta: inout [String:String]) -> Bool {
        guard current == .keyword("domain") || current == .ident("domain") else { return false }
        advance()
        switch current {
        case let .ident(s): meta["domain"] = s; advance(); return true
        case let .keyword(k): meta["domain"] = k; advance(); return true
        default:
            return false
        }
    }

    /// content { dotted.path = number; … } → flatten into metadata "content.dotted.path" = "<number>"
    @inlinable
    func parseContentBlock(into meta: inout [String:String]) -> Bool {
        guard current == .ident("content") || current == .keyword("content") else { return false }
        advance(); try? beginBlock()
        while current != .rBrace && current != .eof {
            let keyPath = readFlatSegments().joined(separator: ".")
            guard !keyPath.isEmpty else { break }
            guard current == .equals else { break }
            advance()
            guard case let .number(n) = current else {
                break
            }
            meta["content.\(keyPath)"] = "\(n)"
            advance()
            if current == .comma { advance() }
        }
        _ = try? endBlock()
        return true
    }
}
