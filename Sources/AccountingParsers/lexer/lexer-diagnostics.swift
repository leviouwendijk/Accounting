import Foundation
import Accounting
import Position

public enum EntryCompilerLexDiagnosticSeverity: String, Codable, Sendable {
    case error
    case warning
}

public enum EntryCompilerLexDiagnosticKind: String, Codable, Sendable {
    case invalidCharacter
    case unterminatedQuotedString
    case missingBlockOpeningBrace
    case unterminatedBlock
    case missingBlockClosingBrace
}

public struct EntryCompilerLexDiagnostic: CustomStringConvertible, Codable, Sendable, Hashable {
    public let severity: EntryCompilerLexDiagnosticSeverity
    public let kind: EntryCompilerLexDiagnosticKind
    public let message: String
    public let span: PositionSpan
    public let lexeme: String?

    public init(
        severity: EntryCompilerLexDiagnosticSeverity,
        kind: EntryCompilerLexDiagnosticKind,
        message: String,
        span: PositionSpan,
        lexeme: String? = nil
    ) {
        self.severity = severity
        self.kind = kind
        self.message = message
        self.span = span
        self.lexeme = lexeme
    }

    public var description: String {
        "\(severity.rawValue): \(message) at \(span.start)"
    }
}

public struct EntryCompilerLexResult: Sendable {
    public let tokens: [EntryCompilerToken]
    public let spans: [PositionSpan]
    public let diagnostics: [EntryCompilerLexDiagnostic]

    public init(
        tokens: [EntryCompilerToken],
        spans: [PositionSpan],
        diagnostics: [EntryCompilerLexDiagnostic]
    ) {
        self.tokens = tokens
        self.spans = spans
        self.diagnostics = diagnostics
    }

    public var lineMap: [Int] {
        spans.map { $0.start.line }
    }

    public var hasErrors: Bool {
        diagnostics.contains { $0.severity == .error }
    }

    public func tokenIndex(
        atLine line: Int,
        column: Int
    ) -> Int? {
        spans.firstIndex { $0.contains(line: line, column: column) }
    }

    public func token(
        atLine line: Int,
        column: Int
    ) -> EntryCompilerToken? {
        guard let i = tokenIndex(atLine: line, column: column) else {
            return nil
        }

        return tokens[i]
    }
}

public struct EntryCompilerLexError: Error, CustomStringConvertible, Sendable {
    public let filePath: String?
    public let diagnostics: [EntryCompilerLexDiagnostic]

    public init(
        filePath: String?,
        diagnostics: [EntryCompilerLexDiagnostic]
    ) {
        self.filePath = filePath
        self.diagnostics = diagnostics
    }

    public var description: String {
        let prefix = filePath.map { "lex failed for \($0)" } ?? "lex failed"
        let body = diagnostics.map(\.description).joined(separator: "\n")

        guard !body.isEmpty else {
            return prefix
        }

        return prefix + "\n" + body
    }
}
