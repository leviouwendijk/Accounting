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
            _ = profile
            _ = presentation
            throw ProjectionRunnerError.taxonomyProjectionNotImplemented
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
            _ = profile
            _ = presentation
            throw ProjectionRunnerError.taxonomyProjectionNotImplemented
        }
    }
}

public enum ProjectionRunnerError: LocalizedError, Sendable {
    case taxonomyProjectionNotImplemented

    public var errorDescription: String? {
        switch self {
        case .taxonomyProjectionNotImplemented:
            return "Taxonomy projection is not implemented yet."
        }
    }
}
