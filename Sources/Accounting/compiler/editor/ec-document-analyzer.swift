import Foundation

public enum ECDocumentAnalyzer {
    public static func analyze(
        source: String,
        flavor: EntryCompilerLexingFlavor
    ) -> ECDocumentAnalysis {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: flavor
        )

        var tokens: [EntryCompilerToken] = []
        var spans: [SourceSpan] = []

        while true {
            let token = lexer.nextToken()
            let span = lexer.lastTokenSpan

            tokens.append(token)

            if let span {
                spans.append(span)
            } else {
                spans.append(
                    SourceSpan(
                        start: SourceLocation(line: 1, column: 1),
                        end: SourceLocation(line: 1, column: 1)
                    )
                )
            }

            if token == .eof {
                break
            }
        }

        let occurrences = zip(tokens, spans).compactMap { token, span in
            occurrence(
                for: token,
                span: span
            )
        }

        return ECDocumentAnalysis(
            source: source,
            flavor: flavor,
            tokens: tokens,
            spans: spans,
            diagnostics: lexer.diagnostics,
            occurrences: occurrences
        )
    }

    public static func semanticTokens(
        from analysis: ECDocumentAnalysis
    ) -> [ECSemanticToken] {
        zip(analysis.tokens, analysis.spans).compactMap { token, span in
            guard token != .eof else {
                return nil
            }

            let kind = semanticKind(for: token)

            let length: Int
            if span.start.line == span.end.line {
                length = max(1, span.end.column - span.start.column + 1)
            } else {
                length = 1
            }

            return ECSemanticToken(
                line: span.start.line - 1,
                startColumn: span.start.column - 1,
                length: length,
                kind: kind
            )
        }
    }
}

private extension ECDocumentAnalyzer {
    @inline(__always)
    static func occurrence(
        for token: EntryCompilerToken,
        span: SourceSpan
    ) -> ECSymbolOccurrence? {
        switch token {
        case .keyword(let s):
            return .init(
                kind: .keyword,
                text: s,
                span: span
            )

        case .ident(let s):
            return .init(
                kind: .identifier,
                text: s,
                span: span
            )

        case .entity(let s):
            return .init(
                kind: .entityReference,
                text: s,
                span: span
            )

        case .account(let s):
            return .init(
                kind: .accountReference,
                text: s,
                span: span
            )

        case .number(let d):
            return .init(
                kind: .number,
                text: NSDecimalNumber(decimal: d).stringValue,
                span: span
            )

        case .string(let s):
            return .init(
                kind: .string,
                text: s,
                span: span
            )

        case .dateLiteral(let s):
            return .init(
                kind: .date,
                text: s,
                span: span
            )

        case .lBrace:
            return .init(kind: .punctuation, text: "{", span: span)

        case .rBrace:
            return .init(kind: .punctuation, text: "}", span: span)

        case .lPar:
            return .init(kind: .punctuation, text: "(", span: span)

        case .rPar:
            return .init(kind: .punctuation, text: ")", span: span)

        case .arrow:
            return .init(kind: .punctuation, text: "->", span: span)

        case .dot:
            return .init(kind: .punctuation, text: ".", span: span)

        case .equals:
            return .init(kind: .punctuation, text: "=", span: span)

        case .comma:
            return .init(kind: .punctuation, text: ",", span: span)

        case .hash:
            return .init(kind: .punctuation, text: "#", span: span)

        case .eof:
            return nil
        }
    }

    @inline(__always)
    static func semanticKind(
        for token: EntryCompilerToken
    ) -> ECSemanticTokenKind {
        switch token {
        case .keyword:
            return .keyword

        case .ident:
            return .variable

        case .number:
            return .number

        case .string:
            return .string

        case .dateLiteral:
            return .property

        case .account:
            return .type

        case .entity:
            return .namespace

        case .arrow,
             .dot,
             .equals,
             .comma,
             .hash:
            return .operatorToken

        case .lBrace,
             .rBrace,
             .lPar,
             .rPar:
            return .operatorToken

        case .eof:
            return .variable
        }
    }
}
