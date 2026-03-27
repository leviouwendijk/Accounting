import Foundation

public extension EntryCompilerLexing {
    mutating func resetLexingState() {
        index = 0
        line = 1
        column = 1

        lastConsumedLine = 1
        lastConsumedColumn = 0

        detailsState = .none
        referenceState = .none

        diagnostics = []
        lastTokenSpan = nil
    }

    mutating func collectLexResult() -> EntryCompilerLexResult {
        resetLexingState()

        var tokens: [EntryCompilerToken] = []
        var spans: [SourceSpan] = []

        while true {
            let token = nextToken()
            tokens.append(token)

            let fallback = SourceSpan(
                start: SourceLocation(line: line, column: column),
                end: SourceLocation(line: line, column: column)
            )

            spans.append(lastTokenSpan ?? fallback)

            if token == .eof {
                break
            }
        }

        return EntryCompilerLexResult(
            tokens: tokens,
            spans: spans,
            diagnostics: diagnostics
        )
    }

    mutating func collectAllTokens() -> [EntryCompilerToken] {
        collectLexResult().tokens
    }

    mutating func collectAllTokensWithLineMap() -> ([EntryCompilerToken], [Int]) {
        let result = collectLexResult()
        return (result.tokens, result.lineMap)
    }
}

// public extension EntryCompilerLexing {
//     mutating func collectAllTokens() -> [EntryCompilerToken] {
//         var tokens: [EntryCompilerToken] = []
//         while true {
//             let t = self.nextToken()
//             tokens.append(t)
//             if t == .eof { break }
//         }
//         return tokens
//     }

//     mutating func collectAllTokensWithLineMap() -> ([EntryCompilerToken], [Int]) {
//         var toks: [EntryCompilerToken] = []
//         var lines: [Int] = []
//         // reset indices if this lexer instance was used before
//         index = 0; line = 1; column = 1

//         while true {
//             let lineAtStart = line
//             let t = self.nextToken()
//             toks.append(t)
//             lines.append(lineAtStart)
//             if t == .eof { break }
//         }
//         return (toks, lines)
//     }
// }
