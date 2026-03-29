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

    /// Field that supports either:
    /// - `label = "..."` (strict scalar string)
    /// - `label { free text ... }` (lenient block text)
    @inlinable
    func parseScalarOrFreeTextField(
        named kw: String
    ) throws -> String {
        if case .ident(let s) = current, s == kw {
            advance()
        } else if case .keyword(let s) = current, s == kw {
            advance()
        } else {
            throw ParserError.unexpectedToken(
                current,
                expected: kw,
                at: loc()
            )
        }

        if current == .lBrace {
            try beginBlock()

            let out = try collectFreeText(
                until: { current == .rBrace || current == .eof },
                mode: .lenient
            )

            try endBlock()
            return out
        }

        try expect(.equals)

        guard case let .string(s) = current else {
            throw ParserError.unexpectedToken(
                current,
                expected: "string or { ... }",
                at: loc()
            )
        }

        advance()
        return s
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
}
