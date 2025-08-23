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
        if case let .ident(s) = current, s == kw {
            advance()
        } else if case let .keyword(s) = current, s == kw {
            advance()
        }

        try beginBlock()

        var out: [String:String] = [:]
        while current != .rBrace && current != .eof {
            // key
            guard case let .ident(k) = current else { break }
            advance()
            try expect(.equals)

            // value: string literal OR multi-token unquoted
            switch current {
            case let .string(s):
                out[k] = s; advance()
            default:
                out[k] = readUnquotedValueForMap()
            }

            // optional comma
            if current == .comma { advance() }
        }

        try endBlock()
        return out
    }

    // collects a free-form unquoted value like `stainless steel` or `M2` or `air M2`.
    // stops before `,` or `}`.
    @inline(__always)
    func readUnquotedValueForMap() -> String {
        var parts: [String] = []
        while current != .comma && current != .rBrace && current != .eof {
            switch current {
            case let .ident(s):       parts.append(s); advance()
            case let .number(n):      parts.append("\(n)"); advance()
            case let .keyword(s):     parts.append(s); advance()
            default:
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
