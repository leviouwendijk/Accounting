import Foundation

public struct ECSourceDocument: Sendable {
    public let title: String
    public let subtitle: String?
    public let files: [ECSourcePresentedFile]

    public init(
        title: String,
        subtitle: String? = nil,
        files: [ECSourcePresentedFile]
    ) {
        self.title = title
        self.subtitle = subtitle
        self.files = files
    }

    public var fileCount: Int {
        files.count
    }

    public var blockCount: Int {
        files.reduce(0) { partial, file in
            partial + file.blockCount
        }
    }
}

public struct ECSourcePresentedFile: Sendable {
    public let relativePath: String
    public let blockCount: Int
    public let blocks: [ECSourcePresentedBlock]

    public init(
        relativePath: String,
        blockCount: Int,
        blocks: [ECSourcePresentedBlock]
    ) {
        self.relativePath = relativePath
        self.blockCount = blockCount
        self.blocks = blocks
    }
}

public struct ECSourcePresentedBlock: Sendable {
    public let kind: ECSourceBlockKind
    public let caption: String
    public let lines: [ECSourcePresentedLine]
    public let renderStartLine: Int
    public let semanticStartLine: Int
    public let endLine: Int
    public let summary: ECSourceBlockSummary?

    public init(
        kind: ECSourceBlockKind,
        caption: String,
        lines: [ECSourcePresentedLine],
        renderStartLine: Int,
        semanticStartLine: Int,
        endLine: Int,
        summary: ECSourceBlockSummary?
    ) {
        self.kind = kind
        self.caption = caption
        self.lines = lines
        self.renderStartLine = renderStartLine
        self.semanticStartLine = semanticStartLine
        self.endLine = endLine
        self.summary = summary
    }
}

public struct ECSourcePresentedLine: Sendable {
    public let number: Int
    public let fragments: [ECSyntaxFragment]

    public init(
        number: Int,
        fragments: [ECSyntaxFragment]
    ) {
        self.number = number
        self.fragments = fragments
    }

    public var text: String {
        fragments.map(\.text).joined()
    }
}
