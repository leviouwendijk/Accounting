import AccountingParsers
import Position
import Syntax

/// Canonical lexical classifications for the existing EntryCompiler language.
/// No accounting parsing, compilation, or rendering occurs in this adapter.
public enum EntryCompilerSyntax {
    public enum Kind: String, SyntaxKind {
        case keyword
        case identifier
        case account
        case entity
        case number
        case string
        case date
        case punctuation
        case comment
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case missing_token_range
        case invalid_token_range(start: Int, end: Int, source_length: Int)
    }

    public static func language() throws -> SyntaxLanguage<Kind> {
        try SyntaxLanguage(id: "ec", definitions: [
            .init(kind: .keyword, role: .keyword),
            .init(kind: .identifier, role: .identifier),
            .init(kind: .account, roles: [.identifier, .reference]),
            .init(kind: .entity, roles: [.identifier, .reference]),
            .init(kind: .number, role: .number),
            .init(kind: .string, role: .string),
            .init(kind: .date, roles: [.string, .custom("date")]),
            .init(kind: .punctuation, role: .punctuation),
            .init(kind: .comment, role: .comment),
        ])
    }

    public static func document(
        source: String,
        flavor: EntryCompilerLexingFlavor,
        sourceID: String? = nil
    ) throws -> SyntaxDocument {
        let scalars = Array(source.unicodeScalars)
        let map = Position.TextMap(source: source)
        var lexer = EntryCompilerLexer(source: source, flavor: flavor)
        var captures: [SyntaxCapture] = []
        var priorEnd = 0

        while true {
            let token = lexer.nextToken()
            guard let scalarRange = lexer.lastTokenScalarRange else {
                throw Error.missing_token_range
            }
            guard scalarRange.lowerBound >= priorEnd,
                  scalarRange.upperBound <= scalars.count else {
                throw Error.invalid_token_range(
                    start: scalarRange.lowerBound,
                    end: scalarRange.upperBound,
                    source_length: scalars.count
                )
            }

            // Only skipped trivia is examined. Quoted strings and free-text
            // blocks have already been consumed as distinct lexer tokens.
            for comment in comments(in: priorEnd..<scalarRange.lowerBound, scalars: scalars) {
                captures.append(try capture(.comment, scalars: comment, map: map))
            }

            if token == .eof { break }
            if let kind = kind(for: token) {
                captures.append(try capture(kind, scalars: scalarRange, map: map))
            }
            priorEnd = scalarRange.upperBound
        }

        return try SyntaxDocument(
            source: source,
            vocabularies: [language().vocabulary()],
            captures: captures,
            sourceID: sourceID
        )
    }

    private static func capture(
        _ kind: Kind,
        scalars: Range<Int>,
        map: Position.TextMap
    ) throws -> SyntaxCapture {
        let start = try map.convert(
            Position.Offset<Position.Unit.UTF32>(scalars.lowerBound),
            to: Position.Unit.UTF8.self
        )
        let end = try map.convert(
            Position.Offset<Position.Unit.UTF32>(scalars.upperBound),
            to: Position.Unit.UTF8.self
        )
        return try SyntaxCapture(
            language: "ec",
            kind: kind,
            segments: [SyntaxSourceRange(start: start, end: end)],
            layer: .lexical
        )
    }

    private static func comments(
        in range: Range<Int>,
        scalars: [UnicodeScalar]
    ) -> [Range<Int>] {
        var found: [Range<Int>] = []
        var cursor = range.lowerBound
        while cursor + 1 < range.upperBound {
            guard scalars[cursor] == "/", scalars[cursor + 1] == "/" else {
                cursor += 1
                continue
            }
            let start = cursor
            cursor += 2
            while cursor < range.upperBound,
                  scalars[cursor] != "\r", scalars[cursor] != "\n" {
                cursor += 1
            }
            found.append(start..<cursor)
        }
        return found
    }

    private static func kind(for token: EntryCompilerToken) -> Kind? {
        switch token {
        case .keyword: .keyword
        case .ident: .identifier
        case .account: .account
        case .entity: .entity
        case .number: .number
        case .string: .string
        case .dateLiteral: .date
        case .lBrace, .rBrace, .lPar, .rPar, .arrow, .dot, .equals, .comma, .hash:
            .punctuation
        case .eof: nil
        }
    }
}
