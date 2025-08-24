import Foundation

public extension EntryCompilerLexing {
    mutating func collectAllTokens() -> [EntryCompilerToken] {
        var tokens: [EntryCompilerToken] = []
        while true {
            let t = self.nextToken()
            tokens.append(t)
            if t == .eof { break }
        }
        return tokens
    }

    mutating func collectAllTokensWithLineMap() -> ([EntryCompilerToken], [Int]) {
        var toks: [EntryCompilerToken] = []
        var lines: [Int] = []
        // reset indices if this lexer instance was used before
        index = 0; line = 1; column = 1

        while true {
            let lineAtStart = line
            let t = self.nextToken()
            toks.append(t)
            lines.append(lineAtStart)
            if t == .eof { break }
        }
        return (toks, lines)
    }
}
