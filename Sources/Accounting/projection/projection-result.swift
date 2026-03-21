import Foundation

public enum ProjectionResult: Sendable {
    case nativeCompile(NativeCompileOutput)
    case nativePeriod(NativePeriodCompileOutput)
}
