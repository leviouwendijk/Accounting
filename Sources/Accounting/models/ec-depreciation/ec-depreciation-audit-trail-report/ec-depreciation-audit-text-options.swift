import Foundation
import Arguments

public enum DepreciationAuditDetailMode: String, Sendable, CaseIterable, ArgumentValue {
    case years
    case months
    case periods
    case covered
}

public enum DepreciationAuditDetailPreset: String, Sendable, CaseIterable, ArgumentValue {
    case monthly
    case periods
    case full

    public var detailModes: [DepreciationAuditDetailMode] {
        switch self {
        case .monthly:
            return [
                .years,
                .months,
            ]

        case .periods:
            return [
                .years,
                .months,
                .periods,
            ]

        case .full:
            return [
                .years,
                .months,
                .periods,
                .covered,
            ]
        }
    }
}

public struct DepreciationAuditTextOptions: Sendable {
    public var title: String
    public var underline: String

    public var showHeader: Bool
    public var includeSummaryBlock: Bool
    public var showFailuresEvenIfCovered: Bool

    public var fractionDigits: Int?
    public var useISODateOnly: Bool

    public var showPerYearAmounts: Bool
    public var showPerMonthAmounts: Bool
    public var showPerPeriodAmounts: Bool

    public init(
        title: String = "Depreciation audit",
        underline: String = "──────────────────",
        showHeader: Bool = true,
        includeSummaryBlock: Bool = true,
        showFailuresEvenIfCovered: Bool = false,
        fractionDigits: Int? = 2,
        useISODateOnly: Bool = true,
        showPerYearAmounts: Bool = true,
        showPerMonthAmounts: Bool = true,
        showPerPeriodAmounts: Bool = false
    ) {
        self.title = title
        self.underline = underline
        self.showHeader = showHeader
        self.includeSummaryBlock = includeSummaryBlock
        self.showFailuresEvenIfCovered = showFailuresEvenIfCovered
        self.fractionDigits = fractionDigits
        self.useISODateOnly = useISODateOnly
        self.showPerYearAmounts = showPerYearAmounts
        self.showPerMonthAmounts = showPerMonthAmounts
        self.showPerPeriodAmounts = showPerPeriodAmounts
    }

    public init(
        title: String = "Depreciation audit",
        underline: String = "──────────────────",
        showHeader: Bool = true,
        includeSummaryBlock: Bool = true,
        fractionDigits: Int? = 2,
        useISODateOnly: Bool = true,
        detailModes: [DepreciationAuditDetailMode]
    ) {
        let modes = Set(detailModes)

        self.init(
            title: title,
            underline: underline,
            showHeader: showHeader,
            includeSummaryBlock: includeSummaryBlock,
            showFailuresEvenIfCovered: modes.contains(.covered),
            fractionDigits: fractionDigits,
            useISODateOnly: useISODateOnly,
            showPerYearAmounts: modes.contains(.years),
            showPerMonthAmounts: modes.contains(.months),
            showPerPeriodAmounts: modes.contains(.periods)
        )
    }

    public init(
        title: String = "Depreciation audit",
        underline: String = "──────────────────",
        showHeader: Bool = true,
        includeSummaryBlock: Bool = true,
        fractionDigits: Int? = 2,
        useISODateOnly: Bool = true,
        detailPreset: DepreciationAuditDetailPreset
    ) {
        self.init(
            title: title,
            underline: underline,
            showHeader: showHeader,
            includeSummaryBlock: includeSummaryBlock,
            fractionDigits: fractionDigits,
            useISODateOnly: useISODateOnly,
            detailModes: detailPreset.detailModes
        )
    }
}
