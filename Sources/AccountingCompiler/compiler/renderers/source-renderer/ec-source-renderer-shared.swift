import Accounting
import Foundation

enum ECSourceRendererShared {
    static func maxLineNumberWidth(
        in document: ECSourceDocument
    ) -> Int {
        let maxNumber = document.files
            .flatMap(\.blocks)
            .flatMap(\.lines)
            .map(\.number)
            .max() ?? 0

        return max(1, String(maxNumber).count)
    }

    static func fileBlockCountLabel(
        _ count: Int
    ) -> String {
        count == 1 ? "1 block" : "\(count) blocks"
    }

    static func makeOutput(
        document: ECSourceDocument,
        options: ECSourcePresentationOptions,
        renderTitle: (String) -> String,
        renderSubtitle: (String) -> String,
        renderFilePath: (String) -> String,
        renderFileMeta: (String) -> String,
        renderRule: (Int) -> String,
        renderBlockCaption: (String) -> String,
        renderLine: (ECSourcePresentedLine, Bool, Int) -> String
    ) -> String {
        var out: [String] = []
        let lineNumberWidth = maxLineNumberWidth(in: document)

        out.append(renderTitle(document.title))

        if let subtitle = document.subtitle, !subtitle.isEmpty {
            out.append(renderSubtitle(subtitle))
        }

        if !document.files.isEmpty {
            out.append("")
        }

        for fileIndex in document.files.indices {
            let file = document.files[fileIndex]

            if fileIndex > 0 {
                out.append("")
            }

            out.append(renderFilePath(file.relativePath))

            if options.includeFileBlockCounts {
                out.append(
                    renderFileMeta(
                        fileBlockCountLabel(file.blockCount)
                    )
                )
            }

            out.append(
                renderRule(
                    max(24, file.relativePath.count)
                )
            )

            for blockIndex in file.blocks.indices {
                let block = file.blocks[blockIndex]

                if blockIndex > 0 {
                    out.append("")

                    if !options.compact {
                        out.append("")
                    }
                }

                out.append(
                    renderBlockCaption(block.caption)
                )

                for line in block.lines {
                    out.append(
                        renderLine(
                            line,
                            options.showLineNumbers,
                            lineNumberWidth
                        )
                    )
                }
            }
        }

        return out.joined(separator: "\n")
    }
}
