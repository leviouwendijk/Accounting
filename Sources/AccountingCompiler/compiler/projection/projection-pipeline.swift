import Accounting
import Foundation

public enum ProjectionPipeline {
    public static func render(
        _ output: NativeCompileOutput,
        as kind: ProjectionKind,
        options: NativeRenderOptions = .init(),
        showProjectionDiagnostics: Bool = false
    ) throws {
        let projected = try ProjectionRunner.project(output, as: kind)
        try ProjectionRenderDispatcher.render(
            projected,
            options: options,
            showProjectionDiagnostics: showProjectionDiagnostics
        )
    }

    public static func render(
        _ output: NativePeriodCompileOutput,
        as kind: ProjectionKind,
        options: NativeRenderOptions = .init(),
        showProjectionDiagnostics: Bool = false
    ) throws {
        let projected = try ProjectionRunner.project(output, as: kind)
        try ProjectionRenderDispatcher.render(
            projected,
            options: options,
            showProjectionDiagnostics: showProjectionDiagnostics
        )
    }
}
