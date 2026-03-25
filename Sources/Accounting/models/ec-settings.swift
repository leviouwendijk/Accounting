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
    public var statementData: StatementDataSettings?
    
    public init(
        entry: EntrySettings,
        aggregation: AggregationSettings,
        statementData: StatementDataSettings? = nil
    ) {
        self.entry = entry
        self.statementData = statementData
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

public struct StatementDataSettings: Codable, Sendable {
    public var company: StatementCompanySettings?

    public init(
        company: StatementCompanySettings? = nil
    ) {
        self.company = company
    }
}

public struct StatementCompanySettings: Codable, Sendable {
    public var name: String?
    public var legalForm: String?
    public var kvk: String?
    public var rsin: String?
    public var btw: String?
    public var address: StatementCompanyAddressSettings?
    public var contact: String?

    public init(
        name: String? = nil,
        legalForm: String? = nil,
        kvk: String? = nil,
        rsin: String? = nil,
        btw: String? = nil,
        address: StatementCompanyAddressSettings? = nil,
        contact: String? = nil
    ) {
        self.name = name
        self.legalForm = legalForm
        self.kvk = kvk
        self.rsin = rsin
        self.btw = btw
        self.address = address
        self.contact = contact
    }

    public var statementCompany: StatementHTMLRenderer.Company {
        .init(self)
    }
}

public struct StatementCompanyAddressSettings: Codable, Sendable {
    public var street: String?
    public var number: String?
    public var areaCode: String?
    public var city: String?

    public init(
        street: String? = nil,
        number: String? = nil,
        areaCode: String? = nil,
        city: String? = nil
    ) {
        self.street = street
        self.number = number
        self.areaCode = areaCode
        self.city = city
    }
}
