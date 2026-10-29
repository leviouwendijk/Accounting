import Foundation
import Primitives

/// The shared, authoritative date model lives in Primitives.
public typealias DateSpecification = Primitives.DateSpecification

extension DateSpecification {
    /// Complete inferred dates using Primitives, retaining Accounting-specific diagnostics.
    public func resolved(using context: DateCompletionContext) throws -> DateSpecification {
        switch self {
        case .absolute:
            return self
        case .infer(let day):
            do {
                return .absolute(try resolve(using: context))
            } catch {
                throw EntryDateInferenceError.badDay(context.year, context.month, day.value)
            }
        }
    }

    /// Complete an inferred date from a validated project period, without reading a path.
    public func resolved(using period: EntrySourcePeriod, timezone: TimeZone) throws -> DateSpecification {
        try resolved(using: period.completionContext(timezone: timezone))
    }

    /// Compatibility boundary while source paths remain in Position.file.
    public func resolved(for entry: Entry, using settings: EntryCompilerSettings) throws -> DateSpecification {
        switch self {
        case .absolute:
            return self
        case .infer:
            guard let path = entry.location?.file, !path.isEmpty else {
                throw EntryDateInferenceError.badPath("<missing file path on entry>")
            }
            let period = try inferEntrySourcePeriod(from: path)
            let timezone = entry.timezone.flatMap(TimeZone.init(identifier:)) ?? settings.entry.defaultTimezone
            return try resolved(using: period, timezone: timezone)
        }
    }
}
