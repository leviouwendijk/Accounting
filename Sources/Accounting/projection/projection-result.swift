import Foundation

public enum ProjectionResult: Sendable {
    case nativeCompile(NativeCompileOutput)
    case nativePeriod(NativePeriodCompileOutput)

    case taxonomyCompile(TaxonomyCompileProjectionOutput)
    case taxonomyPeriod(TaxonomyPeriodProjectionOutput)
}
