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
        // optionally consume leading keyword
        if case let .ident(s) = current, s == kw { advance() }
        else if case let .keyword(s) = current, s == kw { advance() }

        try beginBlock()
        var out: [String:String] = [:]

        while current != .rBrace && current != .eof {
            // tolerate separators/noise
            if current == .comma { advance(); continue }

            // key can be ident or keyword; otherwise skip token defensively
            let key: String
            switch current {
            case let .ident(k):   key = k
            case let .keyword(k): key = k
            default:
                advance(); continue
            }
            advance()
            try expect(.equals)

            // value: string literal OR free-form until ',' or '}'
            if case let .string(s) = current {
                out[key] = s; advance()
            } else {
                out[key] = readUnquotedMapValue()
            }

            if current == .comma { advance() } // optional comma between pairs
        }

        try endBlock()
        return out
    }

    @inline(__always)
    func readUnquotedMapValue() -> String {
        var parts: [String] = []
        while current != .comma && current != .rBrace && current != .eof {
            switch current {
            case let .ident(s):   parts.append(s); advance()
            case let .keyword(s): parts.append(s); advance()
            case let .number(n):  parts.append("\(n)"); advance()
            default:
                // stop on anything else (don’t consume terminator)
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
