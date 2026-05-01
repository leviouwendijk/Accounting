import Accounting
import Foundation

public enum ECSourceTextRenderer {}

extension ECSourceTextRenderer {
    public typealias Options = ECSourcePresentationOptions

    public static func render(
        files: [ECSourceFile],
        options: Options = .init()
    ) -> String {
        let document = ECSourcePresenter.present(
            files: files,
            options: options
        )

        return render(
            document: document,
            options: options
        )
    }

    public static func render(
        document: ECSourceDocument,
        options: Options = .init()
    ) -> String {
        ECSourceRendererShared.makeOutput(
            document: document,
            options: options,
            renderTitle: { $0 },
            renderSubtitle: { $0 },
            renderFilePath: { $0 },
            renderFileMeta: { $0 },
            renderRule: { length in
                String(repeating: "─", count: max(1, length))
            },
            renderBlockCaption: { $0 },
            renderLine: renderedLine
        )
    }

    private static func renderedLine(
        _ line: ECSourcePresentedLine,
        showLineNumbers: Bool,
        lineNumberWidth: Int
    ) -> String {
        guard showLineNumbers else {
            return line.text
        }

        let number = String(line.number)
        let padding = String(
            repeating: " ",
            count: max(0, lineNumberWidth - number.count)
        )

        return "\(padding)\(number) │ \(line.text)"
    }
}

// public enum ECSourceTextRenderer {}

// extension ECSourceTextRenderer {
//     public typealias Options = ECSourcePresentationOptions

//     public static func render(
//         files: [ECSourceFile],
//         options: Options = .init()
//     ) -> String {
//         let document = ECSourcePresenter.present(
//             files: files,
//             options: options
//         )

//         return render(
//             document: document,
//             options: options
//         )
//     }

//     public static func render(
//         document: ECSourceDocument,
//         options: Options = .init()
//     ) -> String {
//         var out: [String] = []
//         let lineNumberWidth = maxLineNumberWidth(in: document)

//         out.append(document.title)

//         if let subtitle = document.subtitle, !subtitle.isEmpty {
//             out.append(subtitle)
//         }

//         if !document.files.isEmpty {
//             out.append("")
//         }

//         for fileIndex in document.files.indices {
//             let file = document.files[fileIndex]

//             if fileIndex > 0 {
//                 out.append("")
//             }

//             out.append(file.relativePath)

//             if options.includeFileBlockCounts {
//                 out.append("\(file.blockCount) block(s)")
//             }

//             out.append(rule(length: max(24, file.relativePath.count)))

//             for blockIndex in file.blocks.indices {
//                 let block = file.blocks[blockIndex]

//                 if blockIndex > 0 {
//                     out.append("")

//                     if !options.compact {
//                         out.append("")
//                     }
//                 }

//                 out.append(block.caption)

//                 for line in block.lines {
//                     out.append(
//                         renderedLine(
//                             line,
//                             showLineNumbers: options.showLineNumbers,
//                             lineNumberWidth: lineNumberWidth
//                         )
//                     )
//                 }
//             }
//         }

//         return out.joined(separator: "\n")
//     }

//     private static func renderedLine(
//         _ line: ECSourcePresentedLine,
//         showLineNumbers: Bool,
//         lineNumberWidth: Int
//     ) -> String {
//         guard showLineNumbers else {
//             return line.text
//         }

//         let number = String(line.number)
//         let padding = String(
//             repeating: " ",
//             count: max(0, lineNumberWidth - number.count)
//         )

//         return "\(padding)\(number) │ \(line.text)"
//     }

//     private static func maxLineNumberWidth(
//         in document: ECSourceDocument
//     ) -> Int {
//         let maxNumber = document.files
//             .flatMap(\.blocks)
//             .flatMap(\.lines)
//             .map(\.number)
//             .max() ?? 0

//         return max(1, String(maxNumber).count)
//     }

//     private static func rule(
//         length: Int
//     ) -> String {
//         String(repeating: "─", count: max(1, length))
//     }
// }
