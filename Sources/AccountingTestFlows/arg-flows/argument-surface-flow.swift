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
            Step("root default child resolves to compile") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "compile",
                    ],
                    "argument-surface.root-default.command-path"
                )
            }

            Step("vat default child resolves to overview") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "vat",
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
                    "argument-surface.vat-default.command-path"
                )

                try Expect.equal(
                    try invocation.value(
                        "period",
                        as: String.self
                    ),
                    "quarter",
                    "argument-surface.vat-default.period"
                )
            }

            Step("assets default child resolves to overview") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "assets",
                    ],
                    spec: try accountingCLIShapeFixtureSpec()
                )

                try Expect.equal(
                    invocation.commandPath.map(\.rawValue),
                    [
                        "ec",
                        "assets",
                        "overview",
                    ],
                    "argument-surface.assets-default.command-path"
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
                    Decimal(string: "0.01"),
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

            Step("projection-style many option and alias parse") {
                let invocation = try Arguments.parse(
                    [
                        "ec",
                        "period",
                        "--presentation",
                        "balance",
                        "income",
                        "--diag",
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
            }

            try cmd("audit") {
                arg(
                    "period",
                    as: String.self,
                    default: "quarter"
                )
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

        try cmd("period") {
            opt(
                "presentation",
                as: String.self,
                take: .many
            )

            flag(
                "projection-diagnostics",
                alias: "diag"
            )
        }

        try cmd("assets") {
            defaultChild("overview")

            try cmd("overview") {}
            try cmd("acquired") {}
            try cmd("validate") {}
            try cmd("shares") {}
        }
    }
}
