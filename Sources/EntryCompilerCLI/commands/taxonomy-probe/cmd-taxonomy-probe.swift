import Accounting
import Arguments
import Foundation

enum TaxonomyProbeCommand: BoundArgumentCommand {
    static let name = "taxonomy-probe"

    static let aliases = [
        "tp",
        "probe",
    ]

    struct Options: ArgumentGroup {
        @Opt(
            "profile",
            default: TaxonomySourceProfile.bd_ihz_2025.rawValue
        )
        var profile: String

        @Opt("entrypoint")
        var entrypoint: String?

        @Opts(
            "presentation",
            take: .many
        )
        var presentation: [String]

        @Opt("zip")
        var zip: String?

        @Opt(
            "mode",
            default: "inspectGenericMapping"
        )
        var mode: String

        @Opts(
            "keywords",
            take: .many
        )
        var keywords: [String]

        @Opts(
            "patterns",
            take: .many
        )
        var patterns: [String]

        @Opt(
            "max-files-to-scan",
            default: 400
        )
        var maxFilesToScan: Int

        @Opt(
            "max-hits",
            default: 80
        )
        var maxHits: Int

        @Opt("chart")
        var chart: String?

        @Group("project")
        var project: ProjectOptions

        @Opt(
            "balance-input",
            default: "project"
        )
        var balanceInput: String

        init() {}
    }

    static func run(
        _ options: Options,
        invocation: ParsedInvocation
    ) async throws {
        guard let resolvedProfile = TaxonomySourceProfile(
            rawValue: options.profile
        ) else {
            throw EntryCompilerCLIError.validation(
                "Invalid profile '\(options.profile)'. Use one of: \(TaxonomySourceProfile.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        guard let resolvedMode = TaxonomyProbeMode(
            rawValue: options.mode
        ) else {
            throw EntryCompilerCLIError.validation(
                "Invalid mode '\(options.mode)'. Use probePackage, inspectGenericMapping, or csvMapping."
            )
        }

        guard let resolvedBalanceInput = TaxonomyProbeBalanceInputMode(
            rawValue: options.balanceInput
        ) else {
            throw EntryCompilerCLIError.validation(
                "Invalid balanceInput '\(options.balanceInput)'. Use demo or project."
            )
        }

        let sourceOverrides = TaxonomySourceOverrides(
            entrypoint: options.entrypoint,
            wantedPresentations: options.presentation.isEmpty ? nil : options.presentation,
            mappingZIP: options.zip,
            probeKeywords: options.keywords.isEmpty ? nil : options.keywords,
            probePatterns: options.patterns.isEmpty ? nil : options.patterns
        )

        let provided = URL(
            fileURLWithPath: options.project.resolvedPath,
            isDirectory: true
        )

        let root = EntryCompilerProject.findRoot(
            startingAt: provided
        ) ?? provided

        let resolvedChart = try resolveChartPathIfNeeded(
            explicitChart: options.chart,
            mode: resolvedMode,
            projectRoot: root.path
        )

        let config = TaxonomyProbeConfig(
            source: resolvedProfile.data.applying(
                overrides: sourceOverrides
            ),
            mode: resolvedMode,
            maxFilesToScan: options.maxFilesToScan,
            maxHits: options.maxHits,
            chartFile: resolvedChart,
            balanceInput: resolvedBalanceInput,
            projectRoot: root.path
        )

        try TaxonomyProberRunner(
            config: config
        )
        .run()
    }

    private static func resolveChartPathIfNeeded(
        explicitChart: String?,
        mode: TaxonomyProbeMode,
        projectRoot: String
    ) throws -> String? {
        if let explicitChart {
            return explicitChart
        }

        switch mode {
        case .probePackage:
            return nil

        case .inspectGenericMapping:
            let root = URL(
                fileURLWithPath: projectRoot,
                isDirectory: true
            )

            let settings = try EntryCompilerSettingsLoader.load(
                from: root
            )

            let project = EntryCompilerProject(
                root: root
            )

            let chartURL = project.resource(
                finding: settings.aggregation.chartFind,
                version: settings.aggregation.chartVersion
            )

            guard FileManager.default.fileExists(
                atPath: chartURL.path
            ) else {
                throw EntryCompilerCLIError.validation(
                    """
                    No --chart was provided, and the chart derived from settings.ec was not found.
                    derived chart path: \(chartURL.path)
                    """
                )
            }

            return chartURL.path

        case .csvMapping:
            return nil
        }
    }
}
