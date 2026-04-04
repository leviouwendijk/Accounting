import Foundation

extension StatementHTMLRenderer {
    public struct Options: Sendable {
        public var title: String = "Financial Statements"
        public var subtitle: String? = nil
        public var currencySymbol: String = "€"
        public var minAbsIncome: Decimal = 0
        public var includeOtherBucket: Bool = false
        public var omitIncomeLevel1Root: Bool = true
        public var company: Company? = nil
        public var hierarchyPrefixStyle: HierarchyPrefixStyle = .spacing
        // public var showSummary: Bool = true
        // public var showRatios: Bool = true
        public var periodShape: PeriodShape? = nil

        public init(
            title: String = "Financial Statements",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            minAbsIncome: Decimal = 0,
            includeOtherBucket: Bool = false,
            omitIncomeLevel1Root: Bool = true,
            company: Company? = nil,
            hierarchyPrefixStyle: HierarchyPrefixStyle = .spacing,
            // showSummary: Bool = true,
            // showRatios: Bool = true
            periodShape: PeriodShape? = nil
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.minAbsIncome = minAbsIncome
            self.includeOtherBucket = includeOtherBucket
            self.omitIncomeLevel1Root = omitIncomeLevel1Root
            self.company = company
            self.hierarchyPrefixStyle = hierarchyPrefixStyle
            // self.showSummary = showSummary
            // self.showRatios = showRatios
            self.periodShape = periodShape
        }
    }

    public enum HierarchyPrefixStyle: Sendable, Codable {
        case spacing
        case tree
    }
}
