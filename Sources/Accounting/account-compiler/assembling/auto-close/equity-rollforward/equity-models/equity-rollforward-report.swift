import Foundation

public struct EquityRollforwardReport: PresentableOutput {
    public let title: String
    public let periods: [EquityReportPeriod]
    public let anchorMessages: [String]
    public let diagnostics: [EquityDiagnostic]
    
    public init(
        title: String,
        periods: [EquityReportPeriod],
        anchorMessages: [String],
        diagnostics: [EquityDiagnostic] = []
    ) {
        self.title = title
        self.periods = periods
        self.anchorMessages = anchorMessages
        self.diagnostics = diagnostics
    }
}

public struct EquityReportPeriod: Sendable {
    public let label: String
    public let rows: PeriodRollforward

    public init(
        label: String,
        rows: PeriodRollforward
    ) {
        self.label = label
        self.rows = rows
    }
}

public struct EquityDiagnostic: Sendable {
    public enum Kind: Sendable {
        case info
        case warning
        case assertion
    }

    public enum Payload: Sendable {
        case none
        case ownerMap([Int: Decimal])
    }

    public let kind: Kind
    public let periodLabel: String?
    public let message: String
    public let payload: Payload

    public init(
        kind: Kind,
        periodLabel: String? = nil,
        message: String,
        payload: Payload = .none
    ) {
        self.kind = kind
        self.periodLabel = periodLabel
        self.message = message
        self.payload = payload
    }
}

public extension EquityDiagnostic {
    static func ownerMap(
        kind: Kind,
        periodLabel: String? = nil,
        message: String,
        map: [Int: Decimal]
    ) -> EquityDiagnostic {
        .init(
            kind: kind,
            periodLabel: periodLabel,
            message: message,
            payload: .ownerMap(map)
        )
    }
}
