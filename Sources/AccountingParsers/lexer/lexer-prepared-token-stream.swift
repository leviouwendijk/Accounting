import Foundation
import Accounting

public struct EntryCompilerPreparedTokenStream: Sendable {
    public let tokens: [EntryCompilerToken]
    public let lineMap: [Int]?
    public let spanMap: [SourceSpan]?
    public let diagnostics: [EntryCompilerLexDiagnostic]

    public init(
        tokens: [EntryCompilerToken],
        lineMap: [Int]?,
        spanMap: [SourceSpan]?,
        diagnostics: [EntryCompilerLexDiagnostic]
    ) {
        self.tokens = tokens
        self.lineMap = lineMap
        self.spanMap = spanMap
        self.diagnostics = diagnostics
    }
}

public extension EntryCompilerLexer {
    mutating func prepareTokenStream(
        trace: Bool,
        filePath: String? = nil
    ) throws -> EntryCompilerPreparedTokenStream {
        if trace {
            let lexed = collectLexResult()

            if lexed.hasErrors {
                throw EntryCompilerLexError(
                    filePath: filePath,
                    diagnostics: lexed.diagnostics
                )
            }

            return EntryCompilerPreparedTokenStream(
                tokens: lexed.tokens,
                lineMap: lexed.lineMap,
                spanMap: lexed.spans,
                diagnostics: lexed.diagnostics
            )
        }

        resetLexingState()

        var tokens: [EntryCompilerToken] = []

        while true {
            let token = nextToken()
            tokens.append(token)

            if token == .eof {
                break
            }
        }

        if diagnostics.contains(where: { $0.severity == .error }) {
            throw EntryCompilerLexError(
                filePath: filePath,
                diagnostics: diagnostics
            )
        }

        return EntryCompilerPreparedTokenStream(
            tokens: tokens,
            lineMap: nil,
            spanMap: nil,
            diagnostics: diagnostics
        )
    }
}
