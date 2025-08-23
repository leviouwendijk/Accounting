import Foundation

public extension EntryCompilerParsing {
    // @inlinable
    // func parseStringMapBlock(named kw: String = "metadata") throws -> [String:String] {
    //     // optionally consume leading keyword/ident
    //     if case .ident(let s) = current, s == kw {
    //         advance()
    //     } else if case .keyword(let s) = current, s == kw {
    //         advance()
    //     }
    //     try beginBlock()
    //     var out: [String:String] = [:]
    //     while current != .rBrace && current != .eof {
    //         guard case let .ident(k) = current else {
    //             throw ParserError.unexpectedToken(current, expected: "identifier (key)", at: loc())
    //         }
    //         advance(); try expect(.equals)
    //         switch current {
    //         case let .string(v): out[k] = v; advance()
    //         case let .ident(v):  out[k] = v; advance()
    //         case let .number(n): out[k] = "\(n)"; advance()
    //         default:
    //             throw ParserError.unexpectedToken(current, expected: "string|identifier|number", at: loc())
    //         }
    //     }
    //     try endBlock()
    //     return out
    // }

    @inlinable
    func parseStringMapBlock(named kw: String = "metadata") throws -> [String:String] {
        // optional leading "metadata"
        switch current {
        case .ident(let s) where s == kw, .keyword(let s) where s == kw:
            advance()
        default: break
        }

        try beginBlock()
        var out: [String:String] = [:]

        while current != .rBrace && current != .eof {
            // tolerate stray '=' at start of a line (defensive)
            if current == .equals { advance(); continue }

            // stop if block ends
            if current == .rBrace { break }

            // key
            guard case let .ident(key) = current else {
                // allow blank lines / trailing commas; otherwise bail
                if current == .comma { advance(); continue }
                throw ParserError.unexpectedToken(current, expected: "identifier (key)", at: loc())
            }
            advance()
            try expect(.equals)

            // value
            let value: String
            switch current {
            case let .string(s):
                value = s; advance()
            default:
                value = readUnquotedValueUntilPairOrBlockEnd()
            }

            out[key] = value

            // optional comma after the pair
            if current == .comma { advance() }
        }

        try endBlock()
        return out
    }

    // Collects a free-form unquoted value like `stainless steel` or `M2`
    // until ',', '}', or the start of the next pair (lookahead: ident + '=').
    @inline(__always)
    func readUnquotedValueUntilPairOrBlockEnd() -> String {
        var parts: [String] = []

        func nextIsKeyStart() -> Bool {
            let i = core.index
            let toks = core.tokens
            guard i < toks.count - 1 else { return false }
            if case .ident = toks[i] , toks[i + 1] == .equals { return true }
            return false
        }

        while current != .comma && current != .rBrace && current != .eof && !nextIsKeyStart() {
            switch current {
            case let .ident(s):   parts.append(s); advance()
            case let .number(n):  parts.append("\(n)"); advance()
            case let .keyword(s): parts.append(s); advance()
            default:
                // stop on anything else (keeps parser in a safe state)
                return parts.joined(separator: " ")
            }
        }
        return parts.joined(separator: " ")
    }

    @inlinable
    func parseStringBlock(named kw: String = "details") throws -> String {
        if case .ident(let s) = current, s == kw {
            advance()
        } else if case .keyword(let s) = current, s == kw {
            advance()
        }
        try beginBlock()
        guard case let .string(txt) = current else {
            throw ParserError.unexpectedToken(current, expected: "string block", at: loc())
        }
        advance(); try endBlock()
        return txt
    }

    @inlinable
    func parseFreeTextBlock(named kw: String = "details") throws -> String {
        if case .ident(let s) = current, s == kw {
            advance()
        } else if case .keyword(let s) = current, s == kw {
            advance()
        }
        try beginBlock()
        var parts: [String] = []
        while current != .rBrace && current != .eof {
            switch current {
            case let .string(s): parts.append(s); advance()
            case let .ident(s):  parts.append(s); advance()
            case let .number(n): parts.append("\(n)"); advance()
            default: break
            }
        }
        try endBlock()
        return parts.joined(separator: " ")
    }
}

// @discardableResult
// func consumeKeywordOrIdent(_ name: String) -> Bool {
//     switch current {
//     case .keyword(name), .ident(name): advance(); return true
//     default: return false
//     }
// }
