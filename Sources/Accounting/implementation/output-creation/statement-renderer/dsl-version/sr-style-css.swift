import Foundation
import Constructors

public enum StatementTheme {
    public static func base() -> CSSStyleSheet {
        CSSStyleSheet(
            rules: [
                // Layout / base
                CSS.rule(
                    "body",
                    CSS.decl("font", "12px -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,Helvetica,Arial,sans-serif"),
                    CSS.decl("margin", "24px")
                ),
                CSS.rule(
                    "h1",
                    CSS.decl("font-size", "20px"),
                    CSS.decl("font-weight", "400"),
                    CSS.decl("margin", "0 0 4px")
                ),
                CSS.rule(
                    ".subtitle",
                    CSS.decl("font-size", "12px"),
                    CSS.decl("color", "#666"),
                    CSS.decl("margin", "0 0 10px")
                ),
                CSS.rule(
                    "h2",
                    CSS.decl("font-size", "16px"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("margin", "12px 0 6px")
                ),

                // Tables
                CSS.rule(
                    "table.tbl",
                    CSS.decl("width", "100%"),
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("margin-top", "8px")
                ),
                CSS.rule(
                    ".tbl thead th",
                    CSS.decl("text-align", "left"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("font-size", "12px"),
                    CSS.decl("color", "#666")
                ),
                CSS.rule(
                    ".tbl td",
                    CSS.decl("padding", "3px 6px"),
                    CSS.decl("border-bottom", "1px dotted #eee"),
                    CSS.decl("vertical-align", "top"),
                    CSS.decl("line-height", "1.35")
                ),
                CSS.rule(
                    ".tbl .col-amt, .tbl .amt",
                    CSS.decl("text-align", "right"),
                    CSS.decl("width", "1%"),
                    CSS.decl("min-width", "8ch"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\""),
                    CSS.decl("line-height", "1.35"),
                    CSS.decl("padding-left", "12px")
                ),
                CSS.rule(
                    ".tbl .label",
                    CSS.decl("white-space", "normal"),
                    CSS.decl("overflow-wrap", "anywhere"),
                    CSS.decl("hyphens", "auto"),
                    CSS.decl("line-height", "1.35")
                ),
                CSS.rule(
                    "tr.total td",
                    CSS.decl("border-top", "1px solid #ddd"),
                    CSS.decl("padding-top", "8px"),
                    CSS.decl("font-weight", "600")
                ),

                // Summary
                CSS.rule(
                    ".summary",
                    CSS.decl("margin-top", "8px"),
                    CSS.decl("color", "#444")
                ),
                CSS.rule(
                    ".ok",
                    CSS.decl("color", "#0a7a28")
                ),
                CSS.rule(
                    ".warn",
                    CSS.decl("color", "#b05a00")
                ),

                // Header layout
                CSS.rule(
                    "header.doc",
                    CSS.decl("display", "grid"),
                    CSS.decl("grid-template-columns", "minmax(0, 1fr) auto"),
                    CSS.decl("align-items", "start"),
                    CSS.decl("column-gap", "32px"),
                    CSS.decl("margin", "0 0 14px 0"),
                    CSS.decl("border-bottom", "1px solid #eee"),
                    CSS.decl("padding-bottom", "10px")
                ),
                CSS.rule(
                    ".company h1",
                    CSS.decl("font-size", "19px"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("margin", "0 0 3px 0")
                ),
                CSS.rule(
                    ".company .small",
                    CSS.decl("font-size", "11px"),
                    CSS.decl("color", "#666"),
                    CSS.decl("line-height", "1.35")
                ),
                CSS.rule(
                    ".company .small + .small",
                    CSS.decl("margin-top", "2px")
                ),
                CSS.rule(
                    ".meta",
                    CSS.decl("text-align", "right"),
                    CSS.decl("line-height", "1.3"),
                    CSS.decl("padding-top", "2px")
                ),
                CSS.rule(
                    ".meta .title",
                    CSS.decl("font-size", "13px"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("margin", "0 0 2px 0")
                ),
                CSS.rule(
                    ".meta .subtitle",
                    CSS.decl("font-size", "11px"),
                    CSS.decl("color", "#666")
                )
            ]
        )
    }
}
