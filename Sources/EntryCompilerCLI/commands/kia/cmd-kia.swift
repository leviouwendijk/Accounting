import Accounting
import AccountingCompiler
// import AccountingParsers
import Arguments
import Foundation
import Interfaces

enum KIACommand: ArgumentCommand {
    static let name = "kia"
    static let defaultChild = Audit.self

    static let children: [ArgumentCommandType] = [
        Audit.self,
    ]

    struct Audit: BoundArgumentCommand {
        static let name = "audit"

        struct Options: ArgumentGroup {
            @Group("project")
            var project: ProjectOptions

            @Opt("year")
            var year: Int?

            @Group("pdf")
            var pdf: PDFOptions

            @Flag("verbose")
            var verbose: Bool

            @Flag("diagnostics")
            var diagnostics: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let provided = URL(
                fileURLWithPath: options.project.resolvedPath,
                isDirectory: true
            )

            let root = EntryCompilerProject.findRoot(
                startingAt: provided
            ) ?? provided

            let compiled = try await EntryCompileDriver.compile(
                projectRoot: root,
                setting: .init(
                    entities: true,
                    accounts: true,
                    transactions: true,
                    entries: true,
                    assertion: true,
                    loc_trace: false
                ),
                verbose: false
            )

            let resolvedYear = options.year
                ?? Calendar(identifier: .gregorian).component(
                    .year,
                    from: Date()
                )

            guard let config = KIAConfigs.netherlands(
                year: resolvedYear
            ) else {
                throw EntryCompilerCLIError.validation(
                    "No KIA config available for year \(resolvedYear)."
                )
            }

            let request = KIAProjectionRequest(
                period: .init(
                    taxYear: resolvedYear
                ),
                config: config
            )

            let result = KIAProjection.run(
                entities: compiled.entities,
                request: request
            )

            print(
                KIARenderer.renderText(
                    result,
                    verbose: options.verbose,
                    diagnostics: options.diagnostics
                )
            )

            guard options.pdf.enabled else {
                return
            }

            let html = KIARenderer.renderHTML(
                result,
                title: "KIA \(resolvedYear)",
                subtitle: "Kleinschaligheidsinvesteringsaftrek",
                verbose: options.verbose,
                diagnostics: options.diagnostics,
                currencySymbol: "€"
            )

            try EntryCompilerPDFWriter.write(
                root: root,
                filename: "kia-\(resolvedYear).pdf",
                html: html,
                margins: options.pdf.margins
            )
        }
    }
}
