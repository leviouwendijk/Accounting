import Foundation

public enum ECSymbolKind: String, Sendable, Codable {
    case keyword
    case identifier
    case entityReference
    case accountReference
    case number
    case string
    case date
    case punctuation
}

public struct ECSymbolOccurrence: Sendable, Codable, Hashable {
    public let kind: ECSymbolKind
    public let text: String
    public let span: SourceSpan

    public init(
        kind: ECSymbolKind,
        text: String,
        span: SourceSpan
    ) {
        self.kind = kind
        self.text = text
        self.span = span
    }
}

public struct ECDocumentAnalysis: Sendable {
    public let source: String
    public let flavor: EntryCompilerLexingFlavor
    public let tokens: [EntryCompilerToken]
    public let spans: [SourceSpan]
    public let diagnostics: [EntryCompilerLexDiagnostic]
    public let occurrences: [ECSymbolOccurrence]

    public init(
        source: String,
        flavor: EntryCompilerLexingFlavor,
        tokens: [EntryCompilerToken],
        spans: [SourceSpan],
        diagnostics: [EntryCompilerLexDiagnostic],
        occurrences: [ECSymbolOccurrence]
    ) {
        self.source = source
        self.flavor = flavor
        self.tokens = tokens
        self.spans = spans
        self.diagnostics = diagnostics
        self.occurrences = occurrences
    }

    @inlinable
    public func occurrence(
        atLine line: Int,
        column: Int
    ) -> ECSymbolOccurrence? {
        occurrences.first {
            $0.span.contains(line: line, column: column)
        }
    }

    @inlinable
    public func tokenIndex(
        atLine line: Int,
        column: Int
    ) -> Int? {
        spans.firstIndex {
            $0.contains(line: line, column: column)
        }
    }
}

public enum ECHoverKind: Sendable {
    case entity
    case account
    case transaction
    case token
}

public struct ECHoverResult: Sendable {
    public let kind: ECHoverKind
    public let title: String
    public let subtitle: String?
    public let body: String

    public init(
        kind: ECHoverKind,
        title: String,
        subtitle: String? = nil,
        body: String
    ) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.body = body
    }
}

public struct ECDefinitionResult: Sendable, Hashable {
    public let file: String
    public let line: Int
    public let column: Int

    public init(
        file: String,
        line: Int,
        column: Int
    ) {
        self.file = file
        self.line = line
        self.column = column
    }
}

public enum ECSemanticTokenKind: String, Sendable, Codable {
    case keyword
    case variable
    case number
    case string
    case type
    case namespace
    case comment
    case operatorToken
    case property
}

public struct ECSemanticToken: Sendable, Codable, Hashable {
    public let line: Int
    public let startColumn: Int
    public let length: Int
    public let kind: ECSemanticTokenKind

    public init(
        line: Int,
        startColumn: Int,
        length: Int,
        kind: ECSemanticTokenKind
    ) {
        self.line = line
        self.startColumn = startColumn
        self.length = length
        self.kind = kind
    }
}

public enum ECCompletionKind: String, Sendable, Codable {
    case keyword
    case entity
    case account
    case transaction
}

public struct ECCompletionItem: Sendable, Codable, Hashable {
    public let kind: ECCompletionKind
    public let label: String
    public let insertText: String
    public let detail: String?
    public let documentation: String?

    public init(
        kind: ECCompletionKind,
        label: String,
        insertText: String? = nil,
        detail: String? = nil,
        documentation: String? = nil
    ) {
        self.kind = kind
        self.label = label
        self.insertText = insertText ?? label
        self.detail = detail
        self.documentation = documentation
    }
}
