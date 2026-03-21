import Foundation

public enum ProjectionRenderDispatcher {
    public static func render(
        _ result: ProjectionResult,
        options: NativeRenderOptions = .init()
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
        }
    }
}
