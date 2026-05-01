import Accounting
import Foundation

public enum ProjectionRunner {
    public static func project(
        _ output: NativeCompileOutput,
        as kind: ProjectionKind
    ) throws -> ProjectionResult {
        switch kind {
        case .native:
            return .nativeCompile(output)

        case .taxonomy(let profile, let presentation):
            let projected = try TaxonomyProjector.projectCompile(
                output,
                profile: profile,
                presentation: presentation
            )
            return .taxonomyCompile(projected)
        }
    }

    public static func project(
        _ output: NativePeriodCompileOutput,
        as kind: ProjectionKind
    ) throws -> ProjectionResult {
        switch kind {
        case .native:
            return .nativePeriod(output)

        case .taxonomy(let profile, let presentation):
            let projected = try TaxonomyProjector.projectPeriod(
                output,
                profile: profile,
                presentation: presentation
            )
            return .taxonomyPeriod(projected)
        }
    }
}
