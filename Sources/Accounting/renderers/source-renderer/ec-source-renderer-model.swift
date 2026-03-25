import Foundation

public struct ECSourceFile: Sendable {
    public let relativePath: String
    public let absolutePath: String
    public let blocks: [ECSourceBlock]

    public init(
        relativePath: String,
        absolutePath: String,
        blocks: [ECSourceBlock]
    ) {
        self.relativePath = relativePath
        self.absolutePath = absolutePath
        self.blocks = blocks
    }

    public func replacingBlocks(
        _ blocks: [ECSourceBlock]
    ) -> ECSourceFile {
        ECSourceFile(
            relativePath: relativePath,
            absolutePath: absolutePath,
            blocks: blocks
        )
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
    public let id: Int?
    public let date: String?
    public let alias: String?
    public let code: String?
    public let groups: [String]

    public init(
        id: Int? = nil,
        date: String? = nil,
        alias: String? = nil,
        code: String? = nil,
        groups: [String] = []
    ) {
        self.id = id
        self.date = date
        self.alias = alias
        self.code = code
        self.groups = groups
    }

    public var compactDescription: String? {
        var parts: [String] = []

        if let id {
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

        if !groups.isEmpty {
            parts.append("groups \(groups.joined(separator: ", "))")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
