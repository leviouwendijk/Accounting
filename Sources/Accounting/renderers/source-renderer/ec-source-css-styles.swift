import Foundation
import CSS

enum ECSourceHTMLRendererCSS {
    static func base(
        compact: Bool
    ) -> CSSStyleSheet {
        let blockSpacing = compact ? "12px" : "18px"
        let lineSize = compact ? "11px" : "12px"
        let lineHeight = compact ? "1.32" : "1.42"

        return CSSStyleSheet(
            rules: [
                rule(
                    "*",
                    decl("box-sizing", "border-box")
                ),

                rule(
                    "html, body",
                    decl("margin", "0"),
                    decl("padding", "0")
                ),

                rule(
                    "body",
                    decl("font-family", #"-apple-system, BlinkMacSystemFont, sans-serif"#),
                    decl("color", "#111827"),
                    decl("background", "white"),
                    decl("padding", "24px")
                ),

                rule(
                    "h1",
                    decl("margin", "0 0 4px 0"),
                    decl("font-size", "24px")
                ),

                rule(
                    ".subtitle",
                    decl("margin-bottom", "18px"),
                    decl("color", "#4b5563"),
                    decl("font-size", "13px")
                ),

                rule(
                    ".src-file",
                    decl("margin-bottom", "22px"),
                    decl("page-break-inside", "avoid"),
                    decl("break-inside", "avoid")
                ),

                rule(
                    ".src-file-header",
                    decl("margin-bottom", "8px")
                ),

                rule(
                    ".src-file-path",
                    decl("font-weight", "700"),
                    decl("font-size", "14px")
                ),

                rule(
                    ".src-file-meta",
                    decl("margin-top", "2px"),
                    decl("color", "#6b7280"),
                    decl("font-size", "12px")
                ),

                rule(
                    ".src-block",
                    decl("border", "1px solid #d1d5db"),
                    decl("border-radius", "8px"),
                    decl("overflow", "hidden"),
                    decl("margin-top", blockSpacing),
                    decl("page-break-inside", "avoid"),
                    decl("break-inside", "avoid")
                ),

                rule(
                    ".src-block-header",
                    decl("padding", "8px 10px"),
                    decl("background", "#f9fafb"),
                    decl("border-bottom", "1px solid #e5e7eb"),
                    decl("font-size", "12px"),
                    decl("font-weight", "600"),
                    decl("color", "#374151")
                ),

                rule(
                    ".src-lines",
                    decl("width", "100%")
                ),

                rule(
                    ".src-line",
                    decl("display", "flex"),
                    decl("align-items", "flex-start"),
                    decl("border-top", "1px solid #f3f4f6"),
                    decl(
                        "font-family",
                        #"ui-monospace, SFMono-Regular, Menlo, Monaco, monospace"#
                    ),
                    decl("font-size", lineSize),
                    decl("line-height", lineHeight)
                ),

                rule(
                    ".src-line:first-child",
                    decl("border-top", "none")
                ),

                rule(
                    ".src-line-no",
                    decl("flex", "0 0 64px"),
                    decl("padding", "4px 8px"),
                    decl("text-align", "right"),
                    decl("color", "#9ca3af"),
                    decl("border-right", "1px solid #f3f4f6"),
                    decl("user-select", "none")
                ),

                rule(
                    ".src-line-text",
                    decl("flex", "1 1 auto"),
                    decl("min-width", "0"),
                    decl("padding", "4px 10px"),
                    decl("white-space", "pre-wrap"),
                    decl("word-break", "break-word"),
                    decl("tab-size", "4")
                ),

                rule(
                    ".src-line-no-hidden",
                    decl("display", "none")
                )
            ],
            media: [
                media(
                    "(max-width: 640px)",
                    rule(
                        "body",
                        decl("padding", "16px")
                    )
                )
            ]
        )
    }
}
