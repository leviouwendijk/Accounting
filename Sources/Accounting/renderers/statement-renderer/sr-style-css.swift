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

                CSS.rule(".sr-weight-0", CSS.decl("font-weight", "600")),
                CSS.rule(".sr-weight-1", CSS.decl("font-weight", "500")),
                CSS.rule(".sr-weight-2", CSS.decl("font-weight", "400")),
                CSS.rule(".sr-weight-3", CSS.decl("font-weight", "400")),

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

                CSS.rule(
                    ".sr-hierarchy-prefix",
                    CSS.decl("font-family", "ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace"),
                    CSS.decl("white-space", "pre"),
                    CSS.decl("display", "inline-block"),
                    CSS.decl("vertical-align", "top"),
                    CSS.decl("margin-right", "2px")
                ),

                // addition
                CSS.rule(
                    ".sr-amount",
                    CSS.decl("display", "inline-block")
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
                // Equity rollforward (scoped under .sr-eq)
                // ------------------------------------------------------------
                CSS.rule(
                    ".sr-eq",
                    CSS.decl("font-family", "-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif"),
                    CSS.decl("font-size", "11.5px"),
                    CSS.decl("line-height", "1.38"),
                    CSS.decl("margin", "24px")
                ),
                CSS.rule(
                    ".sr-eq h1",
                    CSS.decl("font-size", "21px"),
                    CSS.decl("margin", "0 0 8px")
                ),
                CSS.rule(
                    ".sr-eq h2",
                    CSS.decl("font-size", "15px"),
                    CSS.decl("margin", "22px 0 8px")
                ),
                CSS.rule(
                    ".sr-eq .sr-eq-sub",
                    CSS.decl("color", "#666"),
                    CSS.decl("font-size", "11px"),
                    CSS.decl("margin", "-6px 0 14px")
                ),
                CSS.rule(
                    ".sr-eq table.sr-eq-table",
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("width", "100%"),
                    CSS.decl("margin", "14px 0"),
                    CSS.decl("font-size", "11px")
                ),
                CSS.rule(
                    ".sr-eq table.sr-eq-table th, .sr-eq table.sr-eq-table td",
                    CSS.decl("border-bottom", "1px solid #ddd"),
                    CSS.decl("padding", "5px 6px"),
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-eq table.sr-eq-table th.sr-eq-left, .sr-eq table.sr-eq-table td.sr-eq-left",
                    CSS.decl("text-align", "left"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-eq td.sr-eq-amount.sr-eq-neg",
                    CSS.decl("color", "#b00")
                ),
                CSS.rule(
                    ".sr-eq .sr-eq-period",
                    CSS.decl("margin-top", "24px")
                ),
                CSS.rule(
                    ".sr-eq .sr-eq-summary",
                    CSS.decl("margin", "7px 0"),
                    CSS.decl("color", "#444"),
                    CSS.decl("font-size", "11px")
                ),

                // ------------------------------------------------------------
                // VAT overview (scoped under body.sr-vat)
                // ------------------------------------------------------------
                CSS.rule(
                    ".sr-vat",
                    CSS.decl("font-family", "-apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif"),
                    CSS.decl("margin", "48px"),
                    CSS.decl("font-size", "12px")
                ),
                CSS.rule(
                    ".sr-vat h1",
                    CSS.decl("font-size", "20px"),
                    CSS.decl("margin", "0 0 8px")
                ),
                CSS.rule(
                    ".sr-vat h2",
                    CSS.decl("font-size", "16px"),
                    CSS.decl("margin", "24px 0 8px")
                ),
                CSS.rule(
                    ".sr-vat .sr-vat-sub",
                    CSS.decl("color", "#666"),
                    CSS.decl("margin", "0 0 24px")
                ),
                CSS.rule(
                    ".sr-vat table.sr-vat-table",
                    CSS.decl("width", "100%"),
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("margin", "8px 0 16px")
                ),
                CSS.rule(
                    ".sr-vat table.sr-vat-table th, .sr-vat table.sr-vat-table td",
                    CSS.decl("padding", "10px 12px"),
                    CSS.decl("border-bottom", "1px solid #eee")
                ),
                CSS.rule(
                    ".sr-vat table.sr-vat-table th",
                    CSS.decl("text-align", "left"),
                    CSS.decl("font-weight", "600")
                ),
                CSS.rule(
                    ".sr-vat th.sr-vat-amount, .sr-vat td.sr-vat-amount",
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-vat td.sr-vat-label",
                    CSS.decl("width", "60%")
                ),
                CSS.rule(
                    ".sr-vat td.sr-vat-code",
                    CSS.decl("width", "20%"),
                    CSS.decl("color", "#666")
                ),
                CSS.rule(
                    ".sr-vat .sr-vat-neg",
                    CSS.decl("color", "#b00020")
                ),
                CSS.rule(
                    ".sr-vat .sr-vat-summary",
                    CSS.decl("margin-top", "12px")
                ),
                CSS.rule(
                    ".sr-vat .sr-vat-summary table",
                    CSS.decl("margin-top", "4px")
                ),
                CSS.rule(
                    ".sr-vat .sr-vat-note",
                    CSS.decl("color", "#666"),
                    CSS.decl("font-size", "11px"),
                    CSS.decl("margin-top", "6px")
                ),

                // Summary panel
                CSS.rule(
                    ".sr-summary",
                    CSS.decl("margin-top", "18px"),
                    CSS.decl("margin-left", "auto"),
                    CSS.decl("width", "min(420px, 100%)"),
                    CSS.decl("padding", "10px 12px"),
                    CSS.decl("border", "1px solid #e5e7eb"),
                    CSS.decl("border-radius", "10px"),
                    CSS.decl("background", "#fafafa")
                ),
                CSS.rule(
                    ".sr-summary-group",
                    CSS.decl("padding-top", "4px")
                ),
                CSS.rule(
                    ".sr-summary-row",
                    CSS.decl("display", "grid"),
                    CSS.decl("grid-template-columns", "minmax(0, 1fr) auto"),
                    CSS.decl("gap", "16px"),
                    CSS.decl("align-items", "baseline"),
                    CSS.decl("padding", "4px 0")
                ),
                CSS.rule(
                    ".sr-summary > .sr-summary-row + .sr-summary-group, .sr-summary-group + .sr-summary-row",
                    CSS.decl("border-top", "1px solid #eceff3")
                ),
                CSS.rule(
                    ".sr-summary-label",
                    CSS.decl("color", "#4b5563"),
                    CSS.decl("font-size", "12px"),
                    CSS.decl("line-height", "1.35")
                ),
                CSS.rule(
                    ".sr-summary-value",
                    CSS.decl("text-align", "right"),
                    CSS.decl("font-size", "12px"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\""),
                    CSS.decl("color", "#111827"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-summary-children",
                    CSS.decl("margin-top", "2px"),
                    CSS.decl("margin-left", "10px"),
                    CSS.decl("padding-left", "12px"),
                    CSS.decl("border-left", "1px solid #e5e7eb")
                ),
                CSS.rule(
                    ".sr-summary-row-child",
                    CSS.decl("padding", "2px 0")
                ),
                CSS.rule(
                    ".sr-summary-row-child .sr-summary-label",
                    CSS.decl("color", "#6b7280"),
                    CSS.decl("font-size", "11px")
                ),
                CSS.rule(
                    ".sr-summary-value-child",
                    CSS.decl("font-size", "11px"),
                    CSS.decl("font-weight", "500"),
                    CSS.decl("color", "#4b5563")
                ),
                CSS.rule(
                    ".sr-summary-row-diff",
                    CSS.decl("padding-top", "6px")
                ),
                CSS.rule(
                    ".sr-summary-value-warn",
                    CSS.decl("color", "#92400e")
                ),

                // adding page breaking:
                CSS.rule(
                    ".sr-section",
                    CSS.decl("margin-top", "0")
                ),
                CSS.rule(
                    ".sr-section h2",
                    CSS.decl("break-after", "avoid-page"),
                    CSS.decl("page-break-after", "avoid")
                ),
                // balance orientation
                CSS.rule(
                    ".sr-balance-badge",
                    CSS.decl("display", "inline-block"),
                    CSS.decl("margin-left", "0.5em"),
                    CSS.decl("padding", "0.05em 0.45em"),
                    CSS.decl("border", "1px solid #d1d5db"),
                    CSS.decl("border-radius", "999px"),
                    CSS.decl("font-size", "0.72em"),
                    CSS.decl("font-weight", "500"),
                    CSS.decl("line-height", "1.2"),
                    CSS.decl("vertical-align", "baseline"),
                    CSS.decl("color", "#6b7280"),
                    CSS.decl("background", "#f9fafb")
                ),
                CSS.rule(
                    ".sr-balance-badge-contra",
                    CSS.decl("border-style", "dashed"),
                    CSS.decl("font-style", "italic"),
                    CSS.decl("color", "#374151")
                ),

                // negative:
                CSS.rule(
                    ".sr-amount-negative",
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-variant-numeric", "tabular-nums")
                ),

                // ratios
                CSS.rule(
                    ".ratio-label-stack",
                    CSS.decl("display", "flex"),
                    CSS.decl("flex-direction", "column"),
                    CSS.decl("gap", "1px")
                ),
                CSS.rule(
                    ".ratio-label-main",
                    CSS.decl("color", "#111827"),
                    CSS.decl("font-weight", "500"),
                    CSS.decl("line-height", "1.35")
                ),
                CSS.rule(
                    ".ratio-description",
                    CSS.decl("color", "#6b7280"),
                    CSS.decl("font-size", "11px"),
                    CSS.decl("line-height", "1.3")
                ),
                CSS.rule(
                    ".ratio-formula",
                    CSS.decl("color", "#9ca3af"),
                    CSS.decl("font-size", "10px"),
                    CSS.decl("line-height", "1.3"),
                    CSS.decl("font-family", "ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace")
                ),

                // ------------------------------------------------------------
                // Assets overview + KIA PDF table tuning
                // ------------------------------------------------------------
                CSS.rule(
                    ".sr-assets, .sr-kia",
                    CSS.decl("margin", "0"),
                    CSS.decl("font-size", "11px"),
                    CSS.decl("line-height", "1.3")
                ),
                CSS.rule(
                    ".sr-assets h1, .sr-kia h1",
                    CSS.decl("font-size", "18px"),
                    CSS.decl("margin", "0 0 4px")
                ),
                CSS.rule(
                    ".sr-assets h2, .sr-kia h2",
                    CSS.decl("font-size", "15px"),
                    CSS.decl("margin", "12px 0 6px")
                ),
                CSS.rule(
                    ".sr-assets .subtitle, .sr-kia .subtitle",
                    CSS.decl("font-size", "11px"),
                    CSS.decl("margin", "0 0 8px")
                ),
                CSS.rule(
                    ".sr-assets .summary, .sr-kia .summary",
                    CSS.decl("font-size", "11px"),
                    CSS.decl("margin-top", "6px")
                ),

                // ------------------------------------------------------------
                // Assets overview tables (scoped under .sr-assets)
                // ------------------------------------------------------------
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview, .sr-assets table.tbl-assets-summary",
                    CSS.decl("width", "100%"),
                    CSS.decl("table-layout", "fixed"),
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("margin-top", "6px"),
                    CSS.decl("font-size", "10.25px")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview thead th, .sr-assets table.tbl-assets-summary thead th",
                    CSS.decl("padding", "0 3px 6px 3px"),
                    CSS.decl("font-size", "9.5px"),
                    CSS.decl("line-height", "1.1"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto"),
                    CSS.decl("vertical-align", "bottom")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview td, .sr-assets table.tbl-assets-summary td",
                    CSS.decl("padding", "3px 3px"),
                    CSS.decl("vertical-align", "top"),
                    CSS.decl("line-height", "1.22")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview th.col-label, .sr-assets table.tbl-assets-overview td.col-label",
                    CSS.decl("width", "44%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-summary th.col-label, .sr-assets table.tbl-assets-summary td.col-label",
                    CSS.decl("width", "70%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview td.col-money, .sr-assets table.tbl-assets-summary td.col-money",
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-size", "10.25px"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\""),
                    CSS.decl("padding-left", "6px")
                ),
                CSS.rule(
                    ".sr-assets table.tbl-assets-overview th.col-money, .sr-assets table.tbl-assets-summary th.col-money",
                    CSS.decl("text-align", "left"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("font-size", "9.25px"),
                    CSS.decl("line-height", "1.08"),
                    CSS.decl("font-variant-numeric", "normal"),
                    CSS.decl("font-feature-settings", "\"tnum\" 0"),
                    CSS.decl("padding-left", "6px"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-assets .cell-wrap",
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-assets .cell-main",
                    CSS.decl("display", "block"),
                    CSS.decl("min-width", "0"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-assets .cell-meta",
                    CSS.decl("display", "block"),
                    CSS.decl("min-width", "0"),
                    CSS.decl("margin-top", "2px"),
                    CSS.decl("font-size", "9.75px"),
                    CSS.decl("line-height", "1.18"),
                    CSS.decl("color", "#666"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-assets .cell-flags",
                    CSS.decl("display", "block"),
                    CSS.decl("min-width", "0"),
                    CSS.decl("margin-top", "2px"),
                    CSS.decl("font-size", "9.75px"),
                    CSS.decl("line-height", "1.18"),
                    CSS.decl("color", "#b45309"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),

                // ------------------------------------------------------------
                // KIA tables (scoped under .sr-kia)
                // ------------------------------------------------------------
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner, .sr-kia table.tbl-kia-qualified",
                    CSS.decl("width", "100%"),
                    CSS.decl("table-layout", "fixed"),
                    CSS.decl("border-collapse", "collapse"),
                    CSS.decl("margin-top", "6px"),
                    CSS.decl("font-size", "10.25px")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner thead th, .sr-kia table.tbl-kia-qualified thead th",
                    CSS.decl("padding", "0 3px 6px 3px"),
                    CSS.decl("font-size", "9.5px"),
                    CSS.decl("line-height", "1.1"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto"),
                    CSS.decl("vertical-align", "bottom")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner td, .sr-kia table.tbl-kia-qualified td",
                    CSS.decl("padding", "3px 3px"),
                    CSS.decl("vertical-align", "top"),
                    CSS.decl("line-height", "1.22")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner th.col-owner, .sr-kia table.tbl-kia-owner td.col-owner",
                    CSS.decl("width", "42%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner td.col-money",
                    CSS.decl("width", "29%"),
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-size", "10.25px"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\""),
                    CSS.decl("padding-left", "6px")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-owner th.col-money",
                    CSS.decl("width", "29%"),
                    CSS.decl("text-align", "left"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("font-size", "9.25px"),
                    CSS.decl("line-height", "1.08"),
                    CSS.decl("font-variant-numeric", "normal"),
                    CSS.decl("font-feature-settings", "\"tnum\" 0"),
                    CSS.decl("padding-left", "6px"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified th.col-asset, .sr-kia table.tbl-kia-qualified td.col-asset",
                    CSS.decl("width", "25%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified th.col-date, .sr-kia table.tbl-kia-qualified td.col-date",
                    CSS.decl("width", "10%"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified td.col-money",
                    CSS.decl("width", "14%"),
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-size", "10.25px"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\""),
                    CSS.decl("padding-left", "6px")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified th.col-money",
                    CSS.decl("width", "14%"),
                    CSS.decl("text-align", "left"),
                    CSS.decl("white-space", "normal"),
                    CSS.decl("font-size", "9.25px"),
                    CSS.decl("line-height", "1.08"),
                    CSS.decl("font-variant-numeric", "normal"),
                    CSS.decl("font-feature-settings", "\"tnum\" 0"),
                    CSS.decl("padding-left", "6px"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified th.col-shares, .sr-kia table.tbl-kia-qualified td.col-shares",
                    CSS.decl("width", "27%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-kia .kia-cell-wrap",
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-kia .kia-cell-main",
                    CSS.decl("display", "block"),
                    CSS.decl("min-width", "0"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                CSS.rule(
                    ".sr-kia .kia-cell-meta",
                    CSS.decl("display", "block"),
                    CSS.decl("min-width", "0"),
                    CSS.decl("margin-top", "2px"),
                    CSS.decl("font-size", "9.75px"),
                    CSS.decl("line-height", "1.18"),
                    CSS.decl("color", "#666"),
                    CSS.decl("overflow-wrap", "break-word"),
                    CSS.decl("word-break", "normal"),
                    CSS.decl("hyphens", "auto")
                ),
                // CSS.rule(
                //     ".sr-kia .kia-share-line",
                //     CSS.decl("display", "block"),
                //     CSS.decl("min-width", "0"),
                //     CSS.decl("line-height", "1.18"),
                //     CSS.decl("overflow-wrap", "break-word"),
                //     CSS.decl("word-break", "normal"),
                //     CSS.decl("hyphens", "auto")
                // ),
                CSS.rule(
                    ".sr-kia table.tbl-kia-qualified th.col-shares, .sr-kia table.tbl-kia-qualified td.col-shares",
                    CSS.decl("width", "22%"),
                    CSS.decl("min-width", "0")
                ),
                CSS.rule(
                    ".sr-kia .kia-share-table",
                    CSS.decl("width", "auto"),
                    CSS.decl("table-layout", "auto"),
                    CSS.decl("border-collapse", "collapse")
                ),
                CSS.rule(
                    ".sr-kia .kia-share-table td",
                    CSS.decl("padding", "0"),
                    CSS.decl("border", "none"),
                    CSS.decl("vertical-align", "top"),
                    CSS.decl("line-height", "1.18")
                ),
                CSS.rule(
                    ".sr-kia .kia-share-label",
                    CSS.decl("min-width", "0"),
                    CSS.decl("padding-right", "4px"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-kia .kia-share-amount",
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\"")
                ),
                // // for asset share details
                CSS.rule(
                    ".sr-assets tr.assets-share-detail-row > td",
                    CSS.decl("padding-top", "0"),
                    CSS.decl("padding-bottom", "4px")
                ),
                CSS.rule(
                    ".sr-assets .assets-share-detail-cell",
                    CSS.decl("padding-left", "0")
                ),
                CSS.rule(
                    ".sr-assets .assets-share-table",
                    CSS.decl("width", "auto"),
                    CSS.decl("table-layout", "auto"),
                    CSS.decl("border-collapse", "collapse")
                ),
                // CSS.rule(
                //     ".sr-assets .assets-share-table td",
                //     CSS.decl("padding", "0"),
                //     CSS.decl("border", "none"),
                //     CSS.decl("vertical-align", "top"),
                //     CSS.decl("line-height", "1.18")
                // ),
                CSS.rule(
                    ".sr-assets .assets-share-label",
                    CSS.decl("min-width", "0"),
                    CSS.decl("padding-right", "6px"),
                    CSS.decl("white-space", "nowrap")
                ),
                CSS.rule(
                    ".sr-assets .assets-share-amount",
                    CSS.decl("text-align", "right"),
                    CSS.decl("white-space", "nowrap"),
                    CSS.decl("font-variant-numeric", "tabular-nums"),
                    CSS.decl("font-feature-settings", "\"tnum\"")
                ),
            ],

            // adding page breaking:
            media: [
                CSS.media(
                    "print",
                    CSS.rule(
                        ".sr-print-page-break-before",
                        CSS.decl("break-before", "page"),
                        CSS.decl("page-break-before", "always")
                    ),
                    CSS.rule(
                        ".sr-summary",
                        CSS.decl("break-inside", "avoid-page"),
                        CSS.decl("page-break-inside", "avoid")
                    )
                )
            ]
        )
    }
}

extension StatementStyleCSS {
    static func assetsShares() -> CSSStyleSheet {
        CSSStyleSheet(
            rules: [
                rule(
                    "body.sr-assets.sr-assets-shares .sr-assets-shares-period",
                    decl("margin-top", "18px")
                ),

                rule(
                    "body.sr-assets.sr-assets-shares .sr-assets-shares-period:first-of-type",
                    decl("margin-top", "0")
                ),

                rule(
                    "body.sr-assets.sr-assets-shares .sr-assets-shares-period h2",
                    decl("margin-top", "0")
                )
            ],
            media: [
                media(
                    "print",
                    rule(
                        "body.sr-assets.sr-assets-shares .sr-assets-shares-period",
                        decl("break-before", "auto"),
                        decl("page-break-before", "auto"),
                        decl("break-inside", "auto"),
                        decl("page-break-inside", "auto")
                    )
                )
            ]
        )
    }
}
