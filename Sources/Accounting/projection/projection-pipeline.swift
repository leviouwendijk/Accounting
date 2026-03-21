public enum ProjectionPipeline {
    public static func render(
        _ output: NativeCompileOutput,
        as kind: ProjectionKind,
        options: NativeRenderOptions = .init()
    ) throws {
        let projected = try ProjectionRunner.project(output, as: kind)
        try ProjectionRenderDispatcher.render(projected, options: options)
    }

    public static func render(
        _ output: NativePeriodCompileOutput,
        as kind: ProjectionKind,
        options: NativeRenderOptions = .init()
    ) throws {
        let projected = try ProjectionRunner.project(output, as: kind)
        try ProjectionRenderDispatcher.render(projected, options: options)
    }
}
