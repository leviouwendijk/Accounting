import Foundation

public struct ECSourceFile: Sendable {
    public let relativePath: String
    public let absolutePath: String
    public let rawSource: String
    public let blocks: [ECSourceBlock]

    public init(
        relativePath: String,
        absolutePath: String,
        rawSource: String,
        blocks: [ECSourceBlock]
    ) {
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.rawSource = rawSource
        self.blocks = blocks
    }
}

public struct ECSourceBlock: Sendable {
    public let kind: ECSourceBlockKind
    public let source: String
    public let renderStartLine: Int
    public let semanticStartLine: Int
    public let endLine: Int
    public let summary: ECSourceBlockSummary?

    public init(
        kind: ECSourceBlockKind,
        source: String,
        renderStartLine: Int,
        semanticStartLine: Int,
        endLine: Int,
        summary: ECSourceBlockSummary? = nil
    ) {
        self.kind = kind
        self.source = source
        self.renderStartLine = renderStartLine
        self.semanticStartLine = semanticStartLine
        self.endLine = endLine
        self.summary = summary
    }
}

public enum ECSourceBlockKind: String, Sendable, CaseIterable {
    case entry
    case entity
    case account
    case transaction
    case document
    case assertion
    case settings
    case unknown
}

public struct ECSourceBlockSummary: Sendable {
    public let id: String?
    public let date: String?
    public let alias: String?
    public let code: String?

    public init(
        id: String? = nil,
        date: String? = nil,
        alias: String? = nil,
        code: String? = nil
    ) {
        self.id = id
        self.date = date
        self.alias = alias
        self.code = code
    }

    public var compactDescription: String? {
        var parts: [String] = []

        if let id, !id.isEmpty {
            parts.append("id \(id)")
        }

        if let date, !date.isEmpty {
            parts.append(date)
        }

        if let alias, !alias.isEmpty {
            parts.append("alias \(alias)")
        }

        if let code, !code.isEmpty {
            parts.append("code \(code)")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct ECSourceDocumentModel: Sendable {
    let title: String
    let subtitle: String?
    let files: [ECSourceRenderedFile]
}

struct ECSourceRenderedFile: Sendable {
    let relativePath: String
    let blockCount: Int
    let blocks: [ECSourceRenderedBlock]
}

struct ECSourceRenderedBlock: Sendable {
    let kind: ECSourceBlockKind
    let caption: String
    let lines: [ECSourceRenderedLine]
}

struct ECSourceRenderedLine: Sendable {
    let number: Int
    let text: String
}
