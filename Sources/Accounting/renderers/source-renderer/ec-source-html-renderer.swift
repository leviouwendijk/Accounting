import Foundation
import HTML
import CSS

public enum ECSourceHTMLRenderer {}

extension ECSourceHTMLRenderer {
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
        let css = ECSourceHTMLRendererCSS
            .base(compact: options.compact)
            .render(
                options: CSSRenderOptions(
                    ensureTrailingNewline: false
                )
            )

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(document.title)
                    HTML.style(css)
                }

                HTML.body {
                    HTML.h1 {
                        HTML.text(document.title)
                    }

                    if let subtitle = document.subtitle {
                        HTML.div(["class": "subtitle"]) {
                            HTML.text(subtitle)
                        }
                    }

                    for file in document.files {
                        renderFile(
                            file,
                            options: options
                        )
                    }
                }
            }
        }

        return doc.render(default: .minified, doctype: true)
    }

    @HTMLBuilder
    static func renderFile(
        _ file: ECSourcePresentedFile,
        options: Options
    ) -> [any HTMLNode] {
        HTML.section(["class": "src-file"]) {
            HTML.div(["class": "src-file-header"]) {
                HTML.div(["class": "src-file-path"]) {
                    HTML.text(file.relativePath)
                }

                if options.includeFileBlockCounts {
                    HTML.div(["class": "src-file-meta"]) {
                        HTML.text("\(file.blockCount) block(s)")
                    }
                }
            }

            for block in file.blocks {
                renderBlock(
                    block,
                    options: options
                )
            }
        }
    }

    @HTMLBuilder
    static func renderBlock(
        _ block: ECSourcePresentedBlock,
        options: Options
    ) -> [any HTMLNode] {
        HTML.div(["class": "src-block"]) {
            HTML.div(["class": "src-block-header"]) {
                HTML.text(block.caption)
            }

            HTML.div(["class": "src-lines"]) {
                for line in block.lines {
                    renderLine(
                        line,
                        showLineNumbers: options.showLineNumbers
                    )
                }
            }
        }
    }

    static func renderLine(
        _ line: ECSourcePresentedLine,
        showLineNumbers: Bool
    ) -> any HTMLNode {
        HTML.div(["class": "src-line"]) {
            HTML.span([
                "class": showLineNumbers
                    ? "src-line-no"
                    : "src-line-no src-line-no-hidden"
            ]) {
                HTML.text("\(line.number)")
            }

            HTML.span(["class": "src-line-text"]) {
                HTML.text(line.text)
            }
        }
    }
}
