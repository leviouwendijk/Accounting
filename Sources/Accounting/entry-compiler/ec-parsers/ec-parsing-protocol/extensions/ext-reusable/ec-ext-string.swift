import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseStringMapBlock(named kw: String = "metadata") throws -> [String:String] {
        switch current {
        case .ident(let s) where s == kw, .keyword(let s) where s == kw:
            advance()
        default: break
        }

        try beginBlock()
        var out: [String:String] = [:]

        while current != .rBrace && current != .eof {
            if current == .equals { advance(); continue }  // tolerate stray '='
            if current == .rBrace { break }

            // key (ident OR keyword)
            let key: String
            switch current {
            case let .ident(k), let .keyword(k):
                key = k; advance()
            default:
                if current == .comma { advance(); continue }
                throw ParserError.unexpectedToken(current, expected: "identifier (key)", at: loc())
            }

            try expect(.equals)

            let value: String
            switch current {
            case let .string(s):
                value = s; advance()

            case .lBrace:
                value = try readVerbatimBlockBody()

            default:
                value = readUnquotedValueUntilPairOrBlockEnd()
            }

            out[key] = value
            if current == .comma { advance() } // optional trailing comma
        }

        try endBlock()
        return out
    }

    /// `{ ... }` block that may contain words/numbers/keywords and dots (strict: throw on weird tokens)
    @inlinable
    func readVerbatimBlockBody() throws -> String {
        try expect(.lBrace)
        let out = try collectFreeText(
            until: { current == .rBrace || current == .eof },
            mode: .strict(expected: "verbatim block content")
        )
        try expect(.rBrace)
        return out
    }

    /// Unquoted value until ',', '}', EOF, or the start of the next `key =` pair (lenient).
    @inline(__always)
    func readUnquotedValueUntilPairOrBlockEnd() -> String {
        try! collectFreeText( // won't throw in .lenient path
            until: { current == .comma || current == .rBrace || current == .eof || nextIsKeyStart() },
            mode: .lenient
        )
    }

    /// Unquoted value until next known keys begin (e.g. for `name = ACME B.V.` before `iban = ...`) (lenient).
    @inline(__always)
    func readUnquotedValue(untilNextKeys nextKeys: Set<String>) -> String {
        try! collectFreeText(
            until: { current == .comma || current == .rBrace || current == .eof || nextIsOneOfKeysStart(nextKeys) },
            mode: .lenient
        )
    }

    /// `details { "..." }` or tolerant `details { free text with dots }`.
    @inlinable
    func parseStringBlock(named kw: String = "details") throws -> String {
        if case .ident(let s) = current, s == kw { advance() }
        else if case .keyword(let s) = current, s == kw { advance() }

        try beginBlock()

        // strict: quoted string inside the block
        if case let .string(txt) = current {
            advance(); try endBlock()
            return txt
        }

        // tolerant fallback
        let out = try collectFreeText(
            until: { current == .rBrace || current == .eof },
            mode: .lenient
        )
        try endBlock()
        return out
    }

    /// Free text block `{ ... }` (lenient).
    @inlinable
    func parseFreeTextBlock(named kw: String = "details") throws -> String {
        if case .ident(let s) = current, s == kw { advance() }
        else if case .keyword(let s) = current, s == kw { advance() }

        try beginBlock()
        let out = try collectFreeText(
            until: { current == .rBrace || current == .eof },
            mode: .lenient
        )
        try endBlock()
        return out
    }


    // @inlinable
    // func readVerbatimBlockBody() throws -> String {
    //     try expect(.lBrace)
    //     var parts: [String] = []
    //     while current != .rBrace && current != .eof {
    //         switch current {
    //         case let .string(s):  parts.append(s); advance()
    //         case let .ident(s):   parts.append(s); advance()
    //         case let .keyword(s): parts.append(s); advance()
    //         case let .number(n):  parts.append("\(n)"); advance()
    //         case .dot:            parts.append("."); advance()
    //         default:
    //             throw ParserError.unexpectedToken(current, expected: "verbatim block type case", at: loc())
    //         }
    //     }
    //     try expect(.rBrace)
    //     return parts.joined(separator: " ") // manual re-stringing
    // }


    // // Collects a free-form unquoted value like `stainless steel` or `M2`
    // // until ',', '}', or the start of the next pair (lookahead: ident + '=').
    // @inline(__always)
    // func readUnquotedValueUntilPairOrBlockEnd() -> String {
    //     var parts: [String] = []

    //     func nextIsKeyStart() -> Bool {
    //         let i = core.index
    //         let toks = core.tokens
    //         guard i < toks.count - 1 else { return false }
    //         if case .ident = toks[i] , toks[i + 1] == .equals { return true }
    //         return false
    //     }

    //     while current != .comma && current != .rBrace && current != .eof && !nextIsKeyStart() {
    //         switch current {
    //         case let .ident(s):   parts.append(s); advance()
    //         case let .number(n):  parts.append("\(n)"); advance()
    //         case let .keyword(s): parts.append(s); advance()
    //         case .dot:            parts.append("."); advance()
    //         default:
    //             // stop on anything else (keeps parser in a safe state)
    //             return parts.joined(separator: " ")
    //         }
    //     }
    //     return parts.joined(separator: " ")
    // }

    // @inline(__always)
    // func readUnquotedValue(untilNextKeys nextKeys: Set<String>) -> String {
    //     var out = ""
    //     func nextIsKeyStart() -> Bool {
    //         let i = core.index
    //         let toks = core.tokens
    //         guard i < toks.count - 1 else { return false }
    //         switch toks[i] {
    //         case let .ident(k), let .keyword(k):
    //             return nextKeys.contains(k) && toks[i + 1] == .equals
    //         default:
    //             return false
    //         }
    //     }

    //     while current != .comma && current != .rBrace && current != .eof && !nextIsKeyStart() {
    //         switch current {
    //         case let .ident(s), let .keyword(s):
    //             if !out.isEmpty { out.append(" ") }
    //             out.append(s); advance()
    //         case let .number(n):
    //             if !out.isEmpty { out.append(" ") }
    //             out.append("\(n)"); advance()
    //         case .dot:
    //             out.append("."); advance()
    //         default:
    //             break
    //         }
    //         // stop if next token starts a new key
    //         if nextIsKeyStart() { break }
    //     }
    //     return out.trimmingCharacters(in: .whitespacesAndNewlines)
    // }

    // @inlinable
    // func parseStringBlock(named kw: String = "details") throws -> String {
    //     if case .ident(let s) = current, s == kw {
    //         advance()
    //     } else if case .keyword(let s) = current, s == kw {
    //         advance()
    //     }
    //     try beginBlock()
    //     guard case let .string(txt) = current else {
    //         throw ParserError.unexpectedToken(current, expected: "string block", at: loc())
    //     }
    //     advance(); try endBlock()
    //     return txt
    // }

    // @inlinable
    // func parseFreeTextBlock(named kw: String = "details") throws -> String {
    //     if case .ident(let s) = current, s == kw {
    //         advance()
    //     } else if case .keyword(let s) = current, s == kw {
    //         advance()
    //     }
    //     try beginBlock()
    //     var parts: [String] = []
    //     while current != .rBrace && current != .eof {
    //         switch current {
    //         case let .string(s): parts.append(s); advance()
    //         case let .ident(s):  parts.append(s); advance()
    //         case let .number(n): parts.append("\(n)"); advance()
    //         case .dot:           parts.append("."); advance()
    //         default: break
    //         }
    //     }
    //     try endBlock()
    //     return parts.joined(separator: " ")
    // }
}

// @discardableResult
// func consumeKeywordOrIdent(_ name: String) -> Bool {
//     switch current {
//     case .keyword(name), .ident(name): advance(); return true
//     default: return false
//     }
// }
