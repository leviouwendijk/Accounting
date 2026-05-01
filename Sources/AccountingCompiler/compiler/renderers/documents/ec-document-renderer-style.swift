import Accounting
import CSS

extension ECDocumentRenderer {
    internal enum Style {
        static func common() -> CSSStyleSheet {
            CSSStyleSheet(
                rules: [
                    CSS.rule(":root",
                        CSS.decl("--ink", "#111111"),
                        CSS.decl("--paper", "#ffffff"),
                        CSS.decl("--muted", "#6b7280"),
                        CSS.decl("--border", "#e5e7eb"),
                        CSS.decl("--line", "#d9dee4")
                    ),
                    CSS.rule("body",
                        CSS.decl("margin", "0"),
                        CSS.decl("background", "#ffffff"),
                        CSS.decl("color", "var(--ink)"),
                        CSS.decl("font-family", "\"Times New Roman\", Times, serif"),
                        CSS.decl("font-size", "11pt")
                    ),
                    // CSS.rule("@page",
                    //     CSS.decl("size", "A4"),
                    //     CSS.decl("margin", "20mm 18mm 20mm 18mm")
                    // ),
                    CSS.rule(".page",
                        CSS.decl("padding", "0")
                    ),
                    CSS.rule(".section-title",
                        CSS.decl("margin", "24px 0 8px 0"),
                        CSS.decl("font-size", "14px"),
                        CSS.decl("font-weight", "700")
                    ),
                    CSS.rule(".signature-image",
                        CSS.decl("display", "block"),
                        CSS.decl("max-width", "220px"),
                        CSS.decl("width", "220px"),
                        CSS.decl("height", "auto"),
                        CSS.decl("max-height", "64px"),
                        CSS.decl("object-fit", "contain"),
                        CSS.decl("margin", "8px 0 8px 0")
                    ),
                    CSS.rule(".attachments-group",
                        CSS.decl("margin", "12px 0 0 0"),
                        CSS.decl("padding", "12px 0 0 0"),
                        CSS.decl("border-top", "1px solid var(--line)")
                    ),
                    CSS.rule(".attachments-group:first-of-type",
                        CSS.decl("margin-top", "0"),
                        CSS.decl("padding-top", "0"),
                        CSS.decl("border-top", "none")
                    ),
                    CSS.rule(".attachments-list",
                        CSS.decl("margin", "0"),
                        CSS.decl("padding-left", "20px")
                    ),
                    CSS.rule(".attachments-list li",
                        CSS.decl("margin", "0 0 4px 0")
                    ),
                    CSS.rule(".footer-block",
                        CSS.decl("display", "grid"),
                        CSS.decl("grid-template-columns", "1fr 1fr"),
                        CSS.decl("gap", "24px"),
                        CSS.decl("align-items", "start"),
                        CSS.decl("margin-top", "24px"),
                        CSS.decl("padding-top", "12px"),
                        CSS.decl("border-top", "1px solid var(--border)"),
                        CSS.decl("font-size", "10pt"),
                        CSS.decl("line-height", "1.28"),
                        CSS.decl("color", "var(--muted)")
                    ),
                    CSS.rule(".footer-column",
                        CSS.decl("min-width", "0")
                    ),
                    CSS.rule(
                        ".footer-block.has-divider .administrator-column",
                        CSS.decl("padding-left", "24px"),
                        CSS.decl("border-left", "1px solid var(--border)")
                    ),
                    CSS.rule(".footer-line",
                        CSS.decl("margin", "0 0 2px 0"),
                        CSS.decl("color", "inherit")
                    ),
                    CSS.rule(".administrator-line",
                        CSS.decl("margin", "0 0 2px 0"),
                        CSS.decl("color", "inherit")
                    )
                ]
            )
        }

        static func truthfulness() -> CSSStyleSheet {
            CSSStyleSheet(
                rules: [
                    CSS.rule("body",
                        CSS.decl("line-height", "1.38")
                    ),
                    CSS.rule(".letter",
                        CSS.decl("width", "100%"),
                        CSS.decl("max-width", "none"),
                        CSS.decl("margin", "0"),
                        CSS.decl("background", "#ffffff"),
                        CSS.decl("border", "none"),
                        CSS.decl("border-radius", "0"),
                        CSS.decl("box-shadow", "none"),
                        CSS.decl("padding", "0")
                    ),
                    CSS.rule(".letter-title",
                        CSS.decl("margin", "0 0 6px 0"),
                        CSS.decl("font-size", "16px"),
                        CSS.decl("font-weight", "700")
                    ),
                    CSS.rule(".top-row",
                        CSS.decl("display", "flex"),
                        CSS.decl("justify-content", "space-between"),
                        CSS.decl("gap", "18px"),
                        CSS.decl("align-items", "flex-start")
                    ),
                    CSS.rule(".meta",
                        CSS.decl("display", "grid"),
                        CSS.decl("gap", "8px"),
                        CSS.decl("margin", "18px 0 24px 0")
                    ),
                    CSS.rule(".meta-row",
                        CSS.decl("display", "flex"),
                        CSS.decl("gap", "10px")
                    ),
                    CSS.rule(".meta-label",
                        CSS.decl("min-width", "100px"),
                        CSS.decl("font-weight", "600"),
                        CSS.decl("color", "var(--muted)")
                    ),
                    CSS.rule(".signature-wrap",
                        CSS.decl("margin-top", "30px")
                    ),
                    CSS.rule(".signature-image-placeholder",
                        CSS.decl("margin-bottom", "8px"),
                        CSS.decl("color", "var(--muted)")
                    ),
                    CSS.rule(".attachments-block",
                        CSS.decl("margin-top", "8px")
                    )
                ]
            )
        }

        static func discrepancy() -> CSSStyleSheet {
            CSSStyleSheet(
                rules: [
                    CSS.rule("body",
                        CSS.decl("line-height", "1.4")
                    ),
                    CSS.rule(".discrepancy-doc",
                        CSS.decl("width", "100%"),
                        CSS.decl("margin", "0"),
                        CSS.decl("padding", "0")
                    ),
                    CSS.rule(".doc-title",
                        CSS.decl("margin", "0 0 4px 0"),
                        CSS.decl("font-size", "16px"),
                        CSS.decl("font-weight", "700")
                    ),
                    CSS.rule(".doc-sub",
                        CSS.decl("margin", "0 0 16px 0"),
                        CSS.decl("font-size", "11pt"),
                        CSS.decl("color", "var(--muted)")
                    ),
                    CSS.rule(".kv-block",
                        CSS.decl("margin", "0 0 14px 0"),
                        CSS.decl("font-size", "10.5pt"),
                        CSS.decl("color", "var(--muted)")
                    ),
                    CSS.rule(".kv-row",
                        CSS.decl("margin", "0 0 4px 0")
                    ),
                    CSS.rule(".kv-label",
                        CSS.decl("font-weight", "700"),
                        CSS.decl("color", "var(--ink)")
                    ),
                    CSS.rule(".heading",
                        CSS.decl("margin", "16px 0 6px 0"),
                        CSS.decl("font-size", "12pt"),
                        CSS.decl("font-weight", "700")
                    ),
                    CSS.rule(".indent",
                        CSS.decl("padding-left", "12px"),
                        CSS.decl("border-left", "2px solid var(--line)"),
                        CSS.decl("margin", "0 0 12px 0")
                    ),
                    CSS.rule(".label",
                        CSS.decl("display", "block"),
                        CSS.decl("font-weight", "700"),
                        CSS.decl("margin-bottom", "4px")
                    ),
                    CSS.rule(".para",
                        CSS.decl("margin", "0 0 10px 0")
                    ),
                    CSS.rule(".attachments",
                        CSS.decl("margin-top", "14px"),
                        CSS.decl("padding", "10px 12px"),
                        CSS.decl("border", "1px solid var(--line)"),
                        CSS.decl("border-radius", "8px")
                    ),
                    CSS.rule(".attachments-title",
                        CSS.decl("margin", "0 0 6px 0"),
                        CSS.decl("font-weight", "700")
                    ),
                    CSS.rule(".sign",
                        CSS.decl("margin-top", "18px"),
                        CSS.decl("display", "grid"),
                        CSS.decl("grid-template-columns", "1fr 1fr"),
                        CSS.decl("gap", "12px")
                    ),
                    CSS.rule(".box",
                        CSS.decl("border", "1px dashed var(--line)"),
                        CSS.decl("border-radius", "8px"),
                        CSS.decl("padding", "10px 12px"),
                        CSS.decl("min-height", "72px")
                    ),
                    CSS.rule(".sig-line",
                        CSS.decl("margin", "8px 0 8px 0"),
                        CSS.decl("width", "220px"),
                        CSS.decl("max-width", "100%"),
                        CSS.decl("border-bottom", "1px solid var(--ink)")
                    ),
                    CSS.rule(".muted-footer",
                        CSS.decl("margin-top", "14px"),
                        CSS.decl("color", "var(--muted)"),
                        CSS.decl("font-size", "10pt")
                    )
                ]
            )
        }
    }
}
