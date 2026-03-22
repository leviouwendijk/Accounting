import Foundation

public enum ProjectionRenderDispatcher {
    public static func render(
        _ result: ProjectionResult,
        options: NativeRenderOptions = .init(),
        showProjectionDiagnostics: Bool = false
    ) throws {
        switch result {
        case .nativeCompile(let output):
            try NativeCompileRenderer.render(
                output,
                options: options
            )

        case .nativePeriod(let output):
            try NativePeriodRenderer.render(
                output,
                options: options
            )

        case .taxonomyCompile(let output):
            if showProjectionDiagnostics,
               let diagnostics = output.diagnostics {
                TaxonomyShared.renderProjectionDiagnostics(diagnostics)
            }

            TaxonomyRenderer.render(
                output,
                options: .init()
            )

        case .taxonomyPeriod(let output):
            if showProjectionDiagnostics,
               let diagnostics = output.diagnostics {
                TaxonomyShared.renderProjectionDiagnostics(diagnostics)
            }

            TaxonomyRenderer.render(
                output,
                options: .init(
                    comparePrevious: options.comparePrevious
                )
            )
        }
    }
}
