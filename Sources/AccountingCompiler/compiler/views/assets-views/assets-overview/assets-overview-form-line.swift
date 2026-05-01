import Accounting
import Foundation

public struct AssetsOverviewFormLine: Sendable, Hashable {
    public let category: AssetsOverviewCategory
    public let section: AssetsOverviewSection
    public let label: String
    public let columnProfile: AssetsOverviewColumnProfile
    public let sortOrder: Int

    public init(
        category: AssetsOverviewCategory,
        section: AssetsOverviewSection,
        label: String,
        columnProfile: AssetsOverviewColumnProfile,
        sortOrder: Int
    ) {
        self.category = category
        self.section = section
        self.label = label
        self.columnProfile = columnProfile
        self.sortOrder = sortOrder
    }
}

public extension AssetsOverviewFormLine {
    static let all: [AssetsOverviewFormLine] = [
        .init(
            category: .goodwill,
            section: .intangibleFixedAssets,
            label: "Goodwill",
            columnProfile: .intangibleFixedAssets,
            sortOrder: 0
        ),
        .init(
            category: .other_intangible_fixed_assets,
            section: .intangibleFixedAssets,
            label: "Overige immateriële vaste activa",
            columnProfile: .intangibleFixedAssets,
            sortOrder: 1
        ),

        .init(
            category: .buildings_and_land,
            section: .tangibleFixedAssets,
            label: "(Bedrijfs)gebouwen en terreinen",
            columnProfile: .tangibleFixedAssets,
            sortOrder: 10
        ),
        .init(
            category: .machines_and_installations,
            section: .tangibleFixedAssets,
            label: "Machines en installaties",
            columnProfile: .tangibleFixedAssets,
            sortOrder: 11
        ),
        .init(
            category: .other_tangible_fixed_assets,
            section: .tangibleFixedAssets,
            label: "Overige materiële vaste activa",
            columnProfile: .tangibleFixedAssets,
            sortOrder: 12
        ),

        .init(
            category: .financial_fixed_assets,
            section: .financialFixedAssets,
            label: "Financiële vaste activa",
            columnProfile: .financialFixedAssets,
            sortOrder: 20
        ),

        .init(
            category: .inventory,
            section: .inventory,
            label: "Voorraden",
            columnProfile: .inventory,
            sortOrder: 30
        ),
        .init(
            category: .work_in_progress,
            section: .inventory,
            label: "Onderhanden werk",
            columnProfile: .inventory,
            sortOrder: 31
        ),

        .init(
            category: .vat_receivable,
            section: .receivables,
            label: "Vordering omzetbelasting",
            columnProfile: .receivables,
            sortOrder: 40
        ),
        .init(
            category: .trade_debtors,
            section: .receivables,
            label: "Vorderingen op handelsdebiteuren",
            columnProfile: .receivables,
            sortOrder: 41
        ),
        .init(
            category: .other_receivables,
            section: .receivables,
            label: "Overige vorderingen",
            columnProfile: .receivables,
            sortOrder: 42
        ),

        .init(
            category: .securities,
            section: .securities,
            label: "Effecten",
            columnProfile: .securities,
            sortOrder: 50
        ),

        .init(
            category: .liquid_assets,
            section: .liquidAssets,
            label: "Liquide middelen",
            columnProfile: .liquidAssets,
            sortOrder: 60
        ),

        .init(
            category: .unclassified,
            section: .unclassified,
            label: "Niet geclassificeerd",
            columnProfile: .unclassified,
            sortOrder: 99
        )
    ]

    static let byCategory: [AssetsOverviewCategory: AssetsOverviewFormLine] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.category, $0) }
    )

    static let bySection: [AssetsOverviewSection: [AssetsOverviewFormLine]] = Dictionary(
        grouping: all,
        by: \.section
    )
}
