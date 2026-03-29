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

    public func makeEquityRollforwardConfig(
        entity: BusinessEntity = .vof
    ) throws -> EquityRollforwardConfig {
        var cfg = EquityRollforwardConfig(entity: entity)

        if let plan = try statementData?.equity?.selectedDisplayPlan() {
            cfg.ownerDisplayPlan = plan
        }

        return cfg
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
    public var equity: StatementEquitySettings?

    public init(
        company: StatementCompanySettings? = nil,
        equity: StatementEquitySettings? = nil
    ) {
        self.company = company
        self.equity = equity
    }

    // public func makeEquityRollforwardConfig(
    //     entity: BusinessEntity = .vof
    // ) throws -> EquityRollforwardConfig {
    //     var cfg = EquityRollforwardConfig(entity: entity)

    //     if let plan = try equity?.selectedDisplayPlan() {
    //         cfg.ownerDisplayPlan = plan
    //     }

    //     return cfg
    // }
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

public struct StatementEquitySettings: Codable, Sendable {
    public var preset: String?
    public var views: [StatementEquityViewSettings]

    public init(
        preset: String? = nil,
        views: [StatementEquityViewSettings] = []
    ) {
        self.preset = preset
        self.views = views
    }
}

public struct StatementEquityViewSettings: Codable, Sendable {
    public var alias: String
    public var sections: [StatementEquitySectionSettings]

    public init(
        alias: String,
        sections: [StatementEquitySectionSettings]
    ) {
        self.alias = alias
        self.sections = sections
    }
}

public struct StatementEquitySectionSettings: Codable, Sendable {
    public var rows: [StatementEquityRowSettings]

    public init(
        rows: [StatementEquityRowSettings]
    ) {
        self.rows = rows
    }
}

public struct StatementEquityRowSettings: Codable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case owner
        case split
        case subtotal
    }

    public var kind: Kind
    public var owner: StatementEntityPath?
    public var percent: Decimal?
    public var label: String?
    public var members: [StatementEquityMemberSettings]

    public init(
        kind: Kind,
        owner: StatementEntityPath? = nil,
        percent: Decimal? = nil,
        label: String? = nil,
        members: [StatementEquityMemberSettings] = []
    ) {
        self.kind = kind
        self.owner = owner
        self.percent = percent
        self.label = label
        self.members = members
    }
}

public struct StatementEquityMemberSettings: Codable, Sendable {
    public var owner: StatementEntityPath
    public var percent: Decimal

    public init(
        owner: StatementEntityPath,
        percent: Decimal
    ) {
        self.owner = owner
        self.percent = percent
    }
}

public struct StatementEntityPath: Codable, Sendable, Hashable {
    public var segments: [String]

    public init(
        segments: [String]
    ) {
        self.segments = segments
    }
}
