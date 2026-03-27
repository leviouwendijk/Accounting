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

        public init(
            title: String = "Financial Statements",
            subtitle: String? = nil,
            currencySymbol: String = "€",
            minAbsIncome: Decimal = 0,
            includeOtherBucket: Bool = false,
            omitIncomeLevel1Root: Bool = true,
            company: Company? = nil,
            hierarchyPrefixStyle: HierarchyPrefixStyle = .spacing
        ) {
            self.title = title
            self.subtitle = subtitle
            self.currencySymbol = currencySymbol
            self.minAbsIncome = minAbsIncome
            self.includeOtherBucket = includeOtherBucket
            self.omitIncomeLevel1Root = omitIncomeLevel1Root
            self.company = company
            self.hierarchyPrefixStyle = hierarchyPrefixStyle
        }
    }

    public enum HierarchyPrefixStyle: Sendable, Codable {
        case spacing
        case tree
    }
}

extension StatementHTMLRenderer {
    public struct EquityOptions: Sendable {
        public var title: String
        public var subtitle: String?
        public var showAnchorMessages: Bool = true
        public var showDiagnostics: Bool = true
        public var showAllocation: Bool = true
        public var showDrawingsBreakdown: Bool = true
        public var showUnassignedEquity: Bool = true

        public init(
            title: String = "IB equity rollforward",
            subtitle: String? = nil,
            showAnchorMessages: Bool = true,
            showDiagnostics: Bool = true,
            showAllocation: Bool = true,
            showDrawingsBreakdown: Bool = true,
            showUnassignedEquity: Bool = true
        ) {
            self.title = title
            self.subtitle = subtitle
            self.showAnchorMessages = showAnchorMessages
            self.showDiagnostics = showDiagnostics
            self.showAllocation = showAllocation
            self.showDrawingsBreakdown = showDrawingsBreakdown
            self.showUnassignedEquity = showUnassignedEquity
        }
    }
}
