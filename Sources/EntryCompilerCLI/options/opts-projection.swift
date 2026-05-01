import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Methods

struct PresentationOptions: Sendable, ArgumentGroup {
    @Opt(
        "caption",
        default: .label
    )
    var caption: PresentationCaptionStyle

    @Opt(
        "detail",
        default: .standard
    )
    var detail: PresentationDetailStyle

    init() {}
}

struct ProjectionOptions: Sendable, ArgumentGroup {
    @Opt("taxonomy")
    var taxonomy: String?

    @Opts(
        "presentation",
        take: .many
    )
    var presentation: [String]

    @Flag("projection-diagnostics")
    var projectionDiagnostics: Bool

    init() {}
}

struct ProjectionOptionsWithDiagAlias: Sendable, ArgumentGroup {
    @Opt("taxonomy")
    var taxonomy: String?

    @Opts(
        "presentation",
        take: .many
    )
    var presentation: [String]

    @Flag(
        "projection-diagnostics",
        alias: "diag"
    )
    var projectionDiagnostics: Bool

    init() {}
}

enum EntryCompilerProjection {
    static func resolve(
        taxonomy: String?,
        presentation: [String],
        projectionDiagnostics: Bool
    ) throws -> ProjectionKind {
        let trimmedTaxonomy = trimmedOrNil(
            taxonomy
        )

        let hasTaxonomy = trimmedTaxonomy != nil
        let hasPresentation = !presentation.isEmpty

        guard hasTaxonomy else {
            if hasPresentation {
                throw ArgumentValidationError(
                    "--presentation requires --taxonomy <profile>."
                )
            }

            if projectionDiagnostics {
                throw ArgumentValidationError(
                    "--projection-diagnostics/--diag requires --taxonomy <profile>."
                )
            }

            return .native
        }

        return .taxonomy(
            profile: trimmedTaxonomy!,
            presentation: presentation
        )
    }
}
