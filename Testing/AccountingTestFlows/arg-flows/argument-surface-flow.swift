import Arguments
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var argumentSurfaceFlow: TestFlow {
        TestFlow(
            "argument-surface",
            tags: [
                "arguments",
                "cli",
                "migration",
                "shape",
            ]
        ) {
            Step("known command inventory parses") {
                let cases: [(raw: [String], expected: [String], label: String)] = [
                    (
                        ["ec"],
                        ["ec", "compile"],
                        "root-default"
                    ),
                    (
                        ["ec", "compile"],
                        ["ec", "compile"],
                        "compile"
                    ),
                    (
                        ["ec", "compile", "period"],
                        ["ec", "compile", "period"],
                        "compile-period"
                    ),
                    (
                        ["ec", "compile", "equity"],
                        ["ec", "compile", "equity"],
                        "compile-equity"
                    ),
                    (
                        ["ec", "depreciation"],
                        ["ec", "depreciation"],
                        "depreciation"
                    ),
                    (
                        ["ec", "depreciation", "write"],
                        ["ec", "depreciation", "write"],
                        "depreciation-write"
                    ),
                    (
                        ["ec", "depreciation", "clean"],
                        ["ec", "depreciation", "clean"],
                        "depreciation-clean"
                    ),
                    (
                        ["ec", "id", "used"],
                        ["ec", "id", "used"],
                        "id-used"
                    ),
                    (
                        ["ec", "id", "next"],
                        ["ec", "id", "next"],
                        "id-next"
                    ),
                    (
                        ["ec", "rgs-hierarchy"],
                        ["ec", "rgs-hierarchy"],
                        "rgs-hierarchy"
                    ),
                    (
                        ["ec", "equity"],
                        ["ec", "equity"],
                        "equity"
                    ),
                    (
                        ["ec", "period"],
                        ["ec", "period"],
                        "period"
                    ),
                    (
                        ["ec", "vat"],
                        ["ec", "vat", "overview"],
                        "vat-default"
                    ),
                    (
                        ["ec", "vat", "overview"],
                        ["ec", "vat", "overview"],
                        "vat-overview"
                    ),
                    (
                        ["ec", "vat", "audit"],
                        ["ec", "vat", "audit"],
                        "vat-audit"
                    ),
                    (
                        ["ec", "vat", "status"],
                        ["ec", "vat", "status"],
                        "vat-status"
                    ),
                    (
                        ["ec", "taxonomy-probe"],
                        ["ec", "taxonomy-probe"],
                        "taxonomy-probe"
                    ),
                    (
                        ["ec", "kia", "audit"],
                        ["ec", "kia", "audit"],
                        "kia-audit"
                    ),
                    (
                        ["ec", "document", "list"],
                        ["ec", "document", "list"],
                        "document-list"
                    ),
                    (
                        ["ec", "document", "render"],
                        ["ec", "document", "render"],
                        "document-render"
                    ),
                    (
                        ["ec", "assets"],
                        ["ec", "assets", "overview"],
                        "assets-default"
                    ),
                    (
                        ["ec", "assets", "overview"],
                        ["ec", "assets", "overview"],
                        "assets-overview"
                    ),
                    (
                        ["ec", "assets", "acquired"],
                        ["ec", "assets", "acquired"],
                        "assets-acquired"
                    ),
                    (
                        ["ec", "assets", "validate"],
                        ["ec", "assets", "validate"],
                        "assets-validate"
                    ),
                    (
                        ["ec", "assets", "shares"],
                        ["ec", "assets", "shares"],
                        "assets-shares"
                    ),
                    (
                        ["ec", "source", "render"],
                        ["ec", "source", "render"],
                        "source-render"
                    ),
                    (
                        ["ec", "meta", "audit"],
                        ["ec", "meta", "audit"],
                        "meta-audit"
                    ),
                    (
                        ["ec", "cost", "breakdown"],
                        ["ec", "cost", "breakdown"],
                        "cost-breakdown"
                    ),
                ]

                for testCase in cases {
                    let invocation = try Arguments.parse(
                        testCase.raw,
                        spec: try accountingCLIShapeFixtureSpec()
                    )

                    try Expect.equal(
                        invocation.commandPath.map(\.rawValue),
                        testCase.expected,
                        "argument-surface.inventory.\(testCase.label).command-path"
                    )
                }
            }

            Step("vat overview parses shared output options") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "overview",
                        "year",
                        "--project",
                        "/tmp/accounting-project",
                        "--anchor",
                        "2025",
                        "--pdf",
                        "--margins",
                        "25",
                        "--trace",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "vat",
                        "overview",
                    ],
                    "argument-surface.vat-overview.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "year",
                    "argument-surface.vat-overview.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "project",
                        as: String.self
                    ),
                    "/tmp/accounting-project",
                    "argument-surface.vat-overview.project"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2025",
                    "argument-surface.vat-overview.anchor"
                )

                try Expect.equal(
                    try invocation.value(
                        "margins",
                        as: Double.self
                    ),
                    25.0,
                    "argument-surface.vat-overview.margins"
                )

                try Expect.true(
                    try invocation.flag("pdf"),
                    "argument-surface.vat-overview.pdf"
                )

                try Expect.true(
                    try invocation.flag("trace"),
                    "argument-surface.vat-overview.trace"
                )
            }

            Step("vat audit parses tolerance and visibility flags") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "audit",
                        "quarter",
                        "-p",
                        "/tmp/accounting-project",
                        "--anchor",
                        "2026Q1",
                        "--tolerance",
                        "0.02",
                        "--only-flagged",
                        "--hide-entries",
                        "--trace",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "vat",
                        "audit",
                    ],
                    "argument-surface.vat-audit.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "argument-surface.vat-audit.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "project",
                        as: String.self
                    ),
                    "/tmp/accounting-project",
                    "argument-surface.vat-audit.project"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2026Q1",
                    "argument-surface.vat-audit.anchor"
                )

                try Expect.equal(
                    try invocation.value(
                        "tolerance",
                        as: Decimal.self
                    ),
                    Decimal(string: "0.02")!,
                    "argument-surface.vat-audit.tolerance"
                )

                try Expect.true(
                    try invocation.flag("only-flagged"),
                    "argument-surface.vat-audit.only-flagged"
                )

                try Expect.true(
                    try invocation.flag("hide-entries"),
                    "argument-surface.vat-audit.hide-entries"
                )

                try Expect.true(
                    try invocation.flag("trace"),
                    "argument-surface.vat-audit.trace"
                )
            }

            Step("vat status parses first migration option surface") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "status",
                        "quarter",
                        "--anchor",
                        "2026Q1",
                        "--tolerance",
                        "0.01",
                        "--only-flagged",
                        "--hide-entries",
                        "--pdf",
                        "--margins",
                        "30",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "vat",
                        "status",
                    ],
                    "argument-surface.vat-status.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "argument-surface.vat-status.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2026Q1",
                    "argument-surface.vat-status.anchor"
                )

                try Expect.equal(
                    try invocation.value(
                        "tolerance",
                        as: Decimal.self
                    ),
                    Decimal(string: "0.01")!,
                    "argument-surface.vat-status.tolerance"
                )

                try Expect.true(
                    try invocation.flag("only-flagged"),
                    "argument-surface.vat-status.only-flagged"
                )

                try Expect.true(
                    try invocation.flag("hide-entries"),
                    "argument-surface.vat-status.hide-entries"
                )

                try Expect.true(
                    try invocation.flag("pdf"),
                    "argument-surface.vat-status.pdf"
                )

                try Expect.equal(
                    try invocation.value(
                        "margins",
                        as: Double.self
                    ),
                    30.0,
                    "argument-surface.vat-status.margins"
                )
            }

            Step("vat status parses default period and custom range") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "status",
                        "--from",
                        "2025-01-01",
                        "--to",
                        "2025-03-31",
                        "--to-date",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "year",
                    "argument-surface.vat-status.default-period"
                )

                try Expect.equal(
                    try invocation.value(
                        "from",
                        as: String.self
                    ),
                    "2025-01-01",
                    "argument-surface.vat-status.from"
                )

                try Expect.equal(
                    try invocation.value(
                        "to",
                        as: String.self
                    ),
                    "2025-03-31",
                    "argument-surface.vat-status.to"
                )

                try Expect.true(
                    try invocation.flag("to-date"),
                    "argument-surface.vat-status.to-date"
                )
            }

            Step("vat status parses explicit quarter option") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "status",
                        "--quarter",
                        "2025Q4",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    try invocation.value(
                        "quarter",
                        as: String.self
                    ),
                    "2025Q4",
                    "argument-surface.vat-status.quarter-option"
                )
            }

            Step("projection-style many option and alias parse") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "period",
                        "quarter",
                        "--anchor",
                        "2026Q1",
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
                        "--caption",
                        "label",
                        "--detail",
                        "concise",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "period",
                    ],
                    "argument-surface.period.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "argument-surface.period.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2026Q1",
                    "argument-surface.period.anchor"
                )

                try Expect.equal(
                    try invocation.values(
                        "presentation",
                        as: String.self
                    ),
                    [
                        "balance",
                        "income",
                    ],
                    "argument-surface.period.presentation"
                )

                try Expect.true(
                    try invocation.flag("projection-diagnostics"),
                    "argument-surface.period.projection-diagnostics"
                )

                try Expect.equal(
                    try invocation.value(
                        "caption",
                        as: String.self
                    ),
                    "label",
                    "argument-surface.period.caption"
                )

                try Expect.equal(
                    try invocation.value(
                        "detail",
                        as: String.self
                    ),
                    "concise",
                    "argument-surface.period.detail"
                )
            }

            Step("source render parses target selection and output flags") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "source",
                        "render",
                        "-p",
                        "/tmp/accounting-project",
                        "--group",
                        "2025/1/1",
                        "--entry",
                        "42",
                        "--pdf",
                        "--margins",
                        "35",
                        "--trace",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "source",
                        "render",
                    ],
                    "argument-surface.source-render.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "project",
                        as: String.self
                    ),
                    "/tmp/accounting-project",
                    "argument-surface.source-render.project"
                )

                try Expect.equal(
                    try invocation.value(
                        "group",
                        as: String.self
                    ),
                    "2025/1/1",
                    "argument-surface.source-render.group"
                )

                try Expect.equal(
                    try invocation.value(
                        "entry",
                        as: String.self
                    ),
                    "42",
                    "argument-surface.source-render.entry"
                )

                try Expect.equal(
                    try invocation.value(
                        "margins",
                        as: Double.self
                    ),
                    35.0,
                    "argument-surface.source-render.margins"
                )

                try Expect.true(
                    try invocation.flag("pdf"),
                    "argument-surface.source-render.pdf"
                )

                try Expect.true(
                    try invocation.flag("trace"),
                    "argument-surface.source-render.trace"
                )
            }

            Step("meta audit parses many add-group options") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "meta",
                        "audit",
                        "year",
                        "--anchor",
                        "2025",
                        "--add-group",
                        "2025/1/1",
                        "2025/1/2",
                        "--pdf",
                        "--trace",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "meta",
                        "audit",
                    ],
                    "argument-surface.meta-audit.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "year",
                    "argument-surface.meta-audit.period"
                )

                try Expect.equal(
                    try invocation.value(
                        "anchor",
                        as: String.self
                    ),
                    "2025",
                    "argument-surface.meta-audit.anchor"
                )

                try Expect.equal(
                    try invocation.values(
                        "add-group",
                        as: String.self
                    ),
                    [
                        "2025/1/1",
                        "2025/1/2",
                    ],
                    "argument-surface.meta-audit.add-group"
                )

                try Expect.true(
                    try invocation.flag("pdf"),
                    "argument-surface.meta-audit.pdf"
                )

                try Expect.true(
                    try invocation.flag("trace"),
                    "argument-surface.meta-audit.trace"
                )
            }

            Step("unknown top-level command throws") {
                try Expect.throwsError(
                    "argument-surface.unknown-command"
                ) {
                    _ = try Arguments.parse(
                        [
                            "ec",
                            "nope",
                        ],
                        spec: try accountingCLIShapeFixtureSpec()
                    )
                }
            }

            Step("default-child containers forward bare value to child positional") {
                let vatInvocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
                        "month",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    vatInvocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "vat",
                        "overview",
                    ],
                    "argument-surface.vat.default-child.command-path"
                )

                try Expect.equal(
                    try vatInvocation.value(
                        "period",
                        as: String.self
                    ),
                    "month",
                    "argument-surface.vat.default-child.period"
                )

                let assetsInvocation = try Arguments.parse(
                    [
                        "ec",
                        "assets",
                        "quarter",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    assetsInvocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "assets",
                        "overview",
                    ],
                    "argument-surface.assets.default-child.command-path"
                )

                try Expect.equal(
                    try assetsInvocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "argument-surface.assets.default-child.period"
                )
            }

            Step("unknown nested commands throw for containers without default children") {
                try Expect.throwsError(
                    "argument-surface.document.unknown-command"
                ) {
                    _ = try Arguments.parse(
                        [
                            "ec",
                            "document",
                            "nope",
                        ],
                        spec: try accountingCLIShapeFixtureSpec()
                    )
                }

                try Expect.throwsError(
                    "argument-surface.depreciation.unknown-command"
                ) {
                    _ = try Arguments.parse(
                        [
                            "ec",
                            "depreciation",
                            "nope",
                        ],
                        spec: try accountingCLIShapeFixtureSpec()
                    )
                }

                try Expect.throwsError(
                    "argument-surface.id.unknown-command"
                ) {
                    _ = try Arguments.parse(
                        [
                            "ec",
                            "id",
                            "nope",
                        ],
                        spec: try accountingCLIShapeFixtureSpec()
                    )
                }
            }
        }
    }
}

private func accountingCLIShapeFixtureSpec() throws -> CommandSpec {
    try cmd("ec") {
        defaultChild("compile")

        try cmd("compile") {
            flag(
                "verbose",
                short: "v"
            )

            flag("trace")

            try cmd("period") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "presentation",
                    as: String.self,
                    take: .many
                )

                flag(
                    "projection-diagnostics",
                    alias: "diag"
                )

                opt(
                    "caption",
                    as: String.self,
                    default: "label"
                )

                opt(
                    "detail",
                    as: String.self,
                    default: "standard"
                )

                flag("trace")
            }

            try cmd("equity") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                flag("trace")
            }
        }

        try cmd("depreciation") {
            try cmd("write") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                flag("dry-run")
                flag("trace")
            }

            try cmd("clean") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                flag("dry-run")
                flag("trace")
            }
        }

        try cmd("id") {
            try cmd("used") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("entry", as: String.self)
                flag("trace")
            }

            try cmd("next") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("entry", as: String.self)
                flag("trace")
            }
        }

        try cmd("rgs-hierarchy") {
            opt("side", as: String.self)
            opt("max-level", as: Int.self)
            flag("trace")
        }

        try cmd("equity") {
            arg(
                "period",
                as: String.self,
                default: "year"
            )

            opt(
                "project",
                short: "p",
                as: String.self
            )

            opt("anchor", as: String.self)
            opt("from", as: String.self)
            opt("to", as: String.self)
            flag("trace")
        }

        try cmd("period") {
            arg(
                "period",
                as: String.self,
                default: "year"
            )

            opt(
                "project",
                short: "p",
                as: String.self
            )

            opt("anchor", as: String.self)
            opt("from", as: String.self)
            opt("to", as: String.self)

            opt(
                "taxonomy",
                as: String.self
            )

            opt(
                "presentation",
                as: String.self,
                take: .many
            )

            flag(
                "projection-diagnostics",
                alias: "diag"
            )

            flag("hierarchy-diagnostics")

            opt(
                "caption",
                as: String.self,
                default: "label"
            )

            opt(
                "detail",
                as: String.self,
                default: "standard"
            )

            flag("trace")
        }

        try cmd("vat") {
            defaultChild("overview")

            try cmd("overview") {
                arg(
                    "period",
                    as: String.self,
                    default: "quarter"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("trace")
                flag("include-corrections")
            }

            try cmd("audit") {
                arg(
                    "period",
                    as: String.self,
                    default: "quarter"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "tolerance",
                    as: Decimal.self,
                    default: Decimal(string: "0.01")!
                )

                flag("only-flagged")
                flag("hide-entries")
                flag("trace")
            }

            try cmd("status") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                opt("quarter", as: String.self)

                opt(
                    "tolerance",
                    as: Decimal.self,
                    default: Decimal(string: "0.01")!
                )

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("to-date")
                flag("only-flagged")
                flag("hide-entries")
                flag("pdf")
                flag("trace")
            }
        }

        try cmd("taxonomy-probe") {
            opt(
                "project",
                short: "p",
                as: String.self
            )

            opt("taxonomy", as: String.self)
            flag("trace")
        }

        try cmd("kia") {
            try cmd("audit") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                flag("trace")
            }
        }

        try cmd("document") {
            try cmd("list") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                flag("trace")
            }

            try cmd("render") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("document", as: String.self)

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("trace")
            }
        }

        try cmd("assets") {
            defaultChild("overview")

            try cmd("overview") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("diagnostics")
                flag("trace")
            }

            try cmd("acquired") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                flag("trace")
            }

            try cmd("validate") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                flag("trace")
            }

            try cmd("shares") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                flag("trace")
            }
        }

        try cmd("source") {
            try cmd("render") {
                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt(
                    "group",
                    as: String.self
                )

                opt(
                    "entry",
                    as: String.self
                )

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("trace")
            }
        }

        try cmd("meta") {
            try cmd("audit") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)

                opt(
                    "add-group",
                    as: String.self,
                    take: .many
                )

                opt(
                    "margins",
                    as: Double.self,
                    default: 40.0
                )

                flag("pdf")
                flag("trace")
            }
        }

        try cmd("cost") {
            try cmd("breakdown") {
                arg(
                    "period",
                    as: String.self,
                    default: "year"
                )

                opt(
                    "project",
                    short: "p",
                    as: String.self
                )

                opt("anchor", as: String.self)
                opt("from", as: String.self)
                opt("to", as: String.self)
                flag("trace")
            }
        }
    }
}
