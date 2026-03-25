import Foundation

public enum ECSourcePresenter {
    public static func present(
        files: [ECSourceFile],
        options: ECSourcePresentationOptions = .init()
    ) -> ECSourceDocument {
        ECSourceDocument(
            title: options.title,
            subtitle: options.subtitle,
            files: files.map(presentedFile)
        )
    }

    private static func presentedFile(
        from file: ECSourceFile
    ) -> ECSourcePresentedFile {
        ECSourcePresentedFile(
            relativePath: file.relativePath,
            blockCount: file.blocks.count,
            blocks: file.blocks.map(presentedBlock)
        )
    }

    private static func presentedBlock(
        from block: ECSourceBlock
    ) -> ECSourcePresentedBlock {
        let lineTexts = block.source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).map(String.init)

        let lines = lineTexts.enumerated().map { offset, text in
            ECSourcePresentedLine(
                number: block.renderStartLine + offset,
                text: text
            )
        }

        let lineRange = "\(block.renderStartLine)–\(block.endLine)"
        var caption = "\(block.kind.rawValue) · lines \(lineRange)"

        if let summary = block.summary?.compactDescription {
            caption += " · \(summary)"
        }

        return ECSourcePresentedBlock(
            kind: block.kind,
            caption: caption,
            lines: lines,
            renderStartLine: block.renderStartLine,
            semanticStartLine: block.semanticStartLine,
            endLine: block.endLine,
            summary: block.summary
        )
    }
}
