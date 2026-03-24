import Foundation
import CSS

public enum StatementStyleCSS {
    public static func base() -> CSSStyleSheet {
        CSSStyleSheet(
            rules: [
                // hierarchical color shades:
                CSS.rule(".sr-level-0", CSS.decl("color", "#111827")),
                CSS.rule(".sr-level-1", CSS.decl("color", "#374151")),
                CSS.rule(".sr-level-2", CSS.decl("color", "#4b5563")),
                CSS.rule(".sr-level-3", CSS.decl("color", "#6b7280")),

                // ------------------------------------------------------------
                // Base layout used by main statements renderer
                // ------------------------------------------------------------
                CSS.rule(
                    "body",
                    CSS.decl("font", "12px -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif"),
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

                // Tables (main statement)
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
                // CSS.rule(
                //     ".tbl .label",
                //     CSS.decl("white-space", "normal"),
                //     CSS.decl("overflow-wrap", "anywhere"),
                //     CSS.decl("hyphens", "auto"),
                //     CSS.decl("line-height", "1.35")
                // ),
                CSS.rule(
                    ".sr-label",
                    CSS.decl("display", "block")
                ),
                // CSS.rule(
                //     "tr.total td",
                //     CSS.decl("border-top", "1px solid #ddd"),
                //     CSS.decl("padding-top", "8px"),
                //     CSS.decl("font-weight", "600")
                // ),
                CSS.rule(
                    "tr.total td",
                    CSS.decl("border-top", "1px solid #ddd"),
                    CSS.decl("padding-top", "8px"),
                    CSS.decl("font-weight", "600")
                ),
                CSS.rule(
                    ".total .sr-label",
                    CSS.decl("color", "inherit")
                ),
                CSS.rule(
                    ".label strong",
                    CSS.decl("color", "inherit")
                ),

                // Summary + status
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

                // Header layout for main statements
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
                ),

                // ------------------------------------------------------------
                // Equity rollforward (scoped under body.sr-eq)
                // ------------------------------------------------------------
                CSS.rule(
                    "body.sr-eq",
                    CSS.decl("font-family", "-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif"),
                    CSS.decl("font-size", "12px"),
                    CSS.decl("line-height", "1.4"),
                    CSS.decl("margin", "24px")
                ),
                CSS.rule(
                    "body.sr-eq h1",
                    CSS.decl("font-size", "22px"),
                    CSS.decl("margin", "0 0 8px")
                ),
                CSS.rule(
                    "body.sr-eq h2",
                    CSS.decl("font-size", "16px"),
                    CSS.decl("margin", "24px 0 8px")
                ),
                CSS.rule(
                    "body.sr-eq .sr-eq-sub",
                    CSS.decl("color", "#666"),
                    CSS.decl("font-size", "12px"),
                    CSS.decl("margin", "-6px 0 16px")
                ),
                CSS.rule(
                    "body.sr-eq table.sr-eq-table",
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("width", "100%"),
                    CSS.decl("margin", "16px 0"),
                    CSS.decl("font-size", "12px")
                ),
                CSS.rule(
                    "body.sr-eq table.sr-eq-table th, body.sr-eq table.sr-eq-table td",
                    CSS.decl("border-bottom", "1px solid #ddd"),
                    CSS.decl("padding", "6px 8px"),
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    "body.sr-eq table.sr-eq-table th.sr-eq-left, body.sr-eq table.sr-eq-table td.sr-eq-left",
                    CSS.decl("text-align", "left")
                ),
                CSS.rule(
                    "body.sr-eq td.sr-eq-amount.sr-eq-neg",
                    CSS.decl("color", "#b00")
                ),
                CSS.rule(
                    "body.sr-eq .sr-eq-period",
                    CSS.decl("margin-top", "28px")
                ),
                CSS.rule(
                    "body.sr-eq .sr-eq-summary",
                    CSS.decl("margin", "8px 0"),
                    CSS.decl("color", "#444"),
                    CSS.decl("font-size", "12px")
                ),

                // ------------------------------------------------------------
                // VAT overview (scoped under body.sr-vat)
                // ------------------------------------------------------------
                CSS.rule(
                    "body.sr-vat",
                    CSS.decl("font-family", "-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif"),
                    CSS.decl("margin", "48px"),
                    CSS.decl("font-size", "12px")
                ),
                CSS.rule(
                    "body.sr-vat h1",
                    CSS.decl("font-size", "20px"),
                    CSS.decl("margin", "0 0 8px")
                ),
                CSS.rule(
                    "body.sr-vat h2",
                    CSS.decl("font-size", "16px"),
                    CSS.decl("margin", "24px 0 8px")
                ),
                CSS.rule(
                    "body.sr-vat .sr-vat-sub",
                    CSS.decl("color", "#666"),
                    CSS.decl("margin", "0 0 24px")
                ),
                CSS.rule(
                    "body.sr-vat table.sr-vat-table",
                    CSS.decl("width", "100%"),
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("margin", "8px 0 16px")
                ),
                CSS.rule(
                    "body.sr-vat table.sr-vat-table th, body.sr-vat table.sr-vat-table td",
                    CSS.decl("padding", "10px 12px"),
                    CSS.decl("border-bottom", "1px solid #eee")
                ),
                CSS.rule(
                    "body.sr-vat table.sr-vat-table th",
                    CSS.decl("text-align", "left"),
                    CSS.decl("font-weight", "600")
                ),
                CSS.rule(
                    "body.sr-vat th.sr-vat-amount, body.sr-vat td.sr-vat-amount",
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    "body.sr-vat td.sr-vat-label",
                    CSS.decl("width", "60%")
                ),
                CSS.rule(
                    "body.sr-vat td.sr-vat-code",
                    CSS.decl("width", "20%"),
                    CSS.decl("color", "#666")
                ),
                CSS.rule(
                    "body.sr-vat .sr-vat-neg",
                    CSS.decl("color", "#b00020")
                ),
                CSS.rule(
                    "body.sr-vat .sr-vat-summary",
                    CSS.decl("margin-top", "12px")
                ),
                CSS.rule(
                    "body.sr-vat .sr-vat-summary table",
                    CSS.decl("margin-top", "4px")
                ),
                CSS.rule(
                    "body.sr-vat .sr-vat-note",
                    CSS.decl("color", "#666"),
                    CSS.decl("font-size", "11px"),
                    CSS.decl("margin-top", "6px")
                )
            ]
        )
    }
}
