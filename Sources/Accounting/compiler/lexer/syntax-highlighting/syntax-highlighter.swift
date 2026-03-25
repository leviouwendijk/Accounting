import Foundation

// integrate into:
// - source renderer
// - terminal output printer (use lib Terminal for ANSI coloring API)
public enum ECSyntaxHighlighter {
    public static func highlight(
        source: String,
        flavor: EntryCompilerLexingFlavor,
        startingAtLine startLine: Int
    ) -> [ECSyntaxLine] {
        let scalars = Array(source.unicodeScalars)
        let lineRanges = scalarLineRanges(in: scalars)
        let spans = tokenSpans(
            in: source,
            flavor: flavor
        )

        return lineRanges.enumerated().map { offset, lineRange in
            ECSyntaxLine(
                number: startLine + offset,
                fragments: fragments(
                    in: lineRange,
                    scalars: scalars,
                    spans: spans
                )
            )
        }
    }
}

private extension ECSyntaxHighlighter {
    struct TokenSpan: Sendable {
        let range: Range<Int>
        let kind: ECSyntaxKind
    }

    static func tokenSpans(
        in source: String,
        flavor: EntryCompilerLexingFlavor
    ) -> [TokenSpan] {
        var lexer = EntryCompilerLexer(
            source: source,
            flavor: flavor
        )

        var out: [TokenSpan] = []

        while true {
            let startIndex = lexer.index
            let token = lexer.nextToken()
            let endIndex = lexer.index

            if token == .eof {
                break
            }

            guard endIndex > startIndex else {
                continue
            }

            out.append(
                TokenSpan(
                    range: startIndex..<endIndex,
                    kind: syntaxKind(for: token)
                )
            )
        }

        return out
    }

    static func syntaxKind(
        for token: EntryCompilerToken
    ) -> ECSyntaxKind {
        switch token {
        case .keyword(_):
            return .keyword

        case .ident(_):
            return .identifier

        case .number(_):
            return .number

        case .string(_):
            return .string

        case .dateLiteral(_):
            return .date

        case .lBrace,
             .rBrace,
             .lPar,
             .rPar,
             .arrow,
             .dot,
             .equals,
             .comma,
             .hash:
            return .punctuation

        case .eof:
            return .plain
        }
    }

    static func scalarLineRanges(
        in scalars: [UnicodeScalar]
    ) -> [Range<Int>] {
        guard !scalars.isEmpty else {
            return [0..<0]
        }

        var out: [Range<Int>] = []
        var lineStart = 0
        var index = 0

        while index < scalars.count {
            if scalars[index] == "\n" {
                out.append(lineStart..<index)
                lineStart = index + 1
            }

            index += 1
        }

        out.append(lineStart..<scalars.count)
        return out
    }

    static func fragments(
        in lineRange: Range<Int>,
        scalars: [UnicodeScalar],
        spans: [TokenSpan]
    ) -> [ECSyntaxFragment] {
        guard !lineRange.isEmpty else {
            return []
        }

        var out: [ECSyntaxFragment] = []
        var cursor = lineRange.lowerBound

        for span in spans where
            span.range.upperBound > lineRange.lowerBound &&
            span.range.lowerBound < lineRange.upperBound
        {
            let tokenStart = max(
                span.range.lowerBound,
                lineRange.lowerBound
            )
            let tokenEnd = min(
                span.range.upperBound,
                lineRange.upperBound
            )

            if cursor < tokenStart {
                appendFragment(
                    text: string(
                        from: cursor..<tokenStart,
                        scalars: scalars
                    ),
                    kind: .plain,
                    into: &out
                )
            }

            if tokenStart < tokenEnd {
                appendFragment(
                    text: string(
                        from: tokenStart..<tokenEnd,
                        scalars: scalars
                    ),
                    kind: span.kind,
                    into: &out
                )

                cursor = tokenEnd
            }
        }

        if cursor < lineRange.upperBound {
            appendFragment(
                text: string(
                    from: cursor..<lineRange.upperBound,
                    scalars: scalars
                ),
                kind: .plain,
                into: &out
            )
        }

        return out
    }

    static func appendFragment(
        text: String,
        kind: ECSyntaxKind,
        into out: inout [ECSyntaxFragment]
    ) {
        guard !text.isEmpty else {
            return
        }

        if let last = out.last, last.kind == kind {
            out[out.count - 1] = ECSyntaxFragment(
                text: last.text + text,
                kind: kind
            )
            return
        }

        out.append(
            ECSyntaxFragment(
                text: text,
                kind: kind
            )
        )
    }

    static func string(
        from range: Range<Int>,
        scalars: [UnicodeScalar]
    ) -> String {
        String(
            scalars[range].map(Character.init)
        )
    }
}
