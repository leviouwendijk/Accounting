import Accounting
import AccountingParsers
import Foundation

public enum ECSourcePresenter {
    public static func present(
        files: [ECSourceFile],
        options: ECSourcePresentationOptions = .init()
    ) -> ECSourceDocument {
        ECSourceDocument(
            title: options.title,
            subtitle: options.subtitle,
            files: files.map {
                presentedFile(
                    from: $0,
                    options: options
                )
            }
        )
    }

    private static func presentedFile(
        from file: ECSourceFile,
        options: ECSourcePresentationOptions
    ) -> ECSourcePresentedFile {
        ECSourcePresentedFile(
            relativePath: file.relativePath,
            blockCount: file.blocks.count,
            blocks: file.blocks.map {
                presentedBlock(
                    from: $0,
                    options: options
                )
            }
        )
    }

    private static func presentedBlock(
        from block: ECSourceBlock,
        options: ECSourcePresentationOptions
    ) -> ECSourcePresentedBlock {
        let lines = presentedLines(
            from: block,
            options: options
        )

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

    private static func presentedLines(
        from block: ECSourceBlock,
        options: ECSourcePresentationOptions
    ) -> [ECSourcePresentedLine] {
        if options.syntaxHighlighting {
            return ECSyntaxHighlighter.highlight(
                source: block.source,
                flavor: lexingFlavor(for: block.kind),
                startingAtLine: block.renderStartLine
            ).map { line in
                ECSourcePresentedLine(
                    number: line.number,
                    fragments: line.fragments
                )
            }
        }

        let lineTexts = block.source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).map(String.init)

        return lineTexts.enumerated().map { offset, text in
            ECSourcePresentedLine(
                number: block.renderStartLine + offset,
                fragments: [
                    ECSyntaxFragment(
                        text: text,
                        kind: .plain
                    )
                ]
            )
        }
    }

    private static func lexingFlavor(
        for kind: ECSourceBlockKind
    ) -> EntryCompilerLexingFlavor {
        switch kind {
        case .entry:
            return .entries

        case .entity:
            return .entities

        case .account:
            return .accounts

        case .transaction:
            return .transactions

        case .document:
            return .documents

        case .settings:
            return .settings

        case .assertion, .unknown:
            return .fallback
        }
    }
}
