import Accounting
import Arguments
import Foundation
import Methods

struct VATOverviewOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: VATPeriodRequest
    var pdf: PDFOptions
    var trace: Bool
    var includeCorrections: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try VATPeriodRequest(
            arguments: arguments.period
        )
        self.pdf = arguments.pdf
        self.trace = arguments.trace

        // Legacy behavior: VAT overview included corrections by default.
        // The legacy --include-corrections flag was therefore effectively affirmative.
        self.includeCorrections = true
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: VATPeriodRequest.QuarterOptions

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        @Flag("include-corrections")
        var includeCorrections: Bool

        init() {}
    }
}

struct VATAuditOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: VATPeriodRequest
    var pdf: PDFOptions
    var trace: Bool
    var tolerance: Decimal
    var onlyFlagged: Bool
    var hideEntries: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try VATPeriodRequest(
            arguments: arguments.period
        )
        self.pdf = arguments.pdf
        self.trace = arguments.trace
        self.tolerance = arguments.tolerance
        self.onlyFlagged = arguments.onlyFlagged
        self.hideEntries = arguments.hideEntries
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: VATPeriodRequest.QuarterOptions

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        @Opt(
            "tolerance",
            default: Decimal(1) / Decimal(100)
        )
        var tolerance: Decimal

        @Flag("only-flagged")
        var onlyFlagged: Bool

        @Flag("hide-entries")
        var hideEntries: Bool

        init() {}
    }
}

struct VATStatusOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: VATPeriodRequest
    var pdf: PDFOptions
    var trace: Bool
    var tolerance: Decimal
    var onlyFlagged: Bool
    var hideEntries: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try VATPeriodRequest(
            arguments: arguments.period
        )
        self.pdf = arguments.pdf
        self.trace = arguments.trace
        self.tolerance = arguments.tolerance
        self.onlyFlagged = arguments.onlyFlagged
        self.hideEntries = arguments.hideEntries
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: VATPeriodRequest.Options

        @Group("pdf")
        var pdf: PDFOptions

        @Flag("trace")
        var trace: Bool

        @Opt(
            "tolerance",
            default: Decimal(1) / Decimal(100)
        )
        var tolerance: Decimal

        @Flag("only-flagged")
        var onlyFlagged: Bool

        @Flag("hide-entries")
        var hideEntries: Bool

        init() {}
    }
}

struct VATFilingOptions: Sendable, ArgumentParsed {
    typealias ArgumentPayload = Options

    var project: ProjectOptions
    var period: VATPeriodRequest
    var trace: Bool
    var tolerance: Decimal
    var hideSourceRows: Bool

    init(
        arguments: Options
    ) throws {
        self.project = arguments.project
        self.period = try VATPeriodRequest(
            arguments: arguments.period
        )
        self.trace = arguments.trace
        self.tolerance = arguments.tolerance
        self.hideSourceRows = arguments.hideSourceRows
    }

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Group("period")
        var period: VATPeriodRequest.QuarterOptions

        @Flag("trace")
        var trace: Bool

        @Opt(
            "tolerance",
            default: Decimal(1) / Decimal(100)
        )
        var tolerance: Decimal

        @Flag("hide-source-rows")
        var hideSourceRows: Bool

        init() {}
    }
}

struct ProjectOptions: ArgumentGroup {
    @Opt(
        "project",
        short: "p"
    )
    var path: String?

    init() {}

    var resolvedPath: String {
        trimmedOrNil(
            path
        ) ?? FileManager.default.currentDirectoryPath
    }
}

struct PDFOptions: ArgumentGroup {
    @Flag("pdf")
    var enabled: Bool

    @Opt(
        "margins",
        default: 40.0
    )
    var margins: Double

    init() {}
}
