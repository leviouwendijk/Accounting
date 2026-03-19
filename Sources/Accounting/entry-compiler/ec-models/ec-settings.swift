import Foundation

public enum EntryCompilerSettingsError: Error, LocalizedError, Sendable {
    case invalidTimezone(String)

    public var errorDescription: String? {
        switch self {
        case .invalidTimezone(let tz):
            return "Invalid timezone identifier: \(tz)"
        }
    }
}

public struct EntryCompilerSettings: Codable, Sendable {
    public var entry: EntrySettings
    public var aggregation: AggregationSettings
    
    public init(
        entry: EntrySettings,
        aggregation: AggregationSettings
    ) {
        self.entry = entry
        self.aggregation = aggregation
    }
}

public struct EntrySettings: Codable, Sendable {
    public var defaultTimezone: TimeZone
    
    public init(
        defaultTimezone: TimeZone
    ) {
        self.defaultTimezone = defaultTimezone
    }
}

public struct AggregationSettings: Codable, Sendable {
    public var includePreviousPeriods: Bool
    public var chartFind: String            // e.g. "rgs"
    public var chartVersion: ChartVersion
    
    public init(
        includePreviousPeriods: Bool,
        chartFind: String,            // e.g. "rgs"
        chartVersion: ChartVersion
    ) {
        self.includePreviousPeriods = includePreviousPeriods
        self.chartFind = chartFind
        self.chartVersion = chartVersion
    }
}
