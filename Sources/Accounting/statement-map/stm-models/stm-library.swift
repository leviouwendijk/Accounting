import Foundation

public enum StatementLibrary {
    public static func balanceIFRS(materiality: Decimal = 0) -> StatementDef {
        StatementDef(
            name: "IFRS – Balance Sheet",
            kind: .balance,
            rows: [
                .init(id: .init(raw: "assets"),     label: "Assets",     kind: .balance,
                      materialityThreshold: materiality,
                      rgs: [.init(includeCodes: nil, includePrefixes: ["10","11","12"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "equity"),     label: "Equity",     kind: .balance,
                      materialityThreshold: 0,
                      rgs: [.init(includeCodes: nil, includePrefixes: ["30"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "liabilities"),label: "Liabilities",kind: .balance,
                      materialityThreshold: 0,
                      rgs: [.init(includeCodes: nil, includePrefixes: ["20","21","22"], includeLevel: nil, filterDirection: nil)])
            ]
        )
    }

    public static func incomeStatementIFRS(materiality: Decimal = 0) -> StatementDef {
        // Adjust prefixes to your RGS catalog for revenue/COGS/Opex/Other income/finance costs, etc.
        StatementDef(
            name: "IFRS – Income Statement",
            kind: .income,
            rows: [
                .init(id: .init(raw: "revenue"), label: "Revenue", kind: .income,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["40","41"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "cogs"),    label: "Cost of Sales", kind: .income,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["50"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "opex"),    label: "Operating Expenses", kind: .income,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["60","61","62"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "other"),   label: "Other Income/Expense", kind: .income,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["70"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "finance"), label: "Finance Income/Costs", kind: .income,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["71","72"], includeLevel: nil, filterDirection: nil)])
            ]
        )
    }

    public static func cashSimple(materiality: Decimal = 0) -> StatementDef {
        // Simple family-based CF (good for a first pass). Later: switch to movement rules.
        StatementDef(
            name: "IFRS – Cash Flow (Simple)",
            kind: .cash,
            rows: [
                .init(id: .init(raw: "operating"), label: "Cash from Operating Activities", kind: .cash,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["40","50","60","61","62"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "investing"), label: "Cash from Investing Activities", kind: .cash,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["12"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "financing"), label: "Cash from Financing Activities", kind: .cash,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["30"], includeLevel: nil, filterDirection: nil)])
            ]
        )
    }

    public static func equityView(materiality: Decimal = 0) -> StatementDef {
        StatementDef(
            name: "IFRS – Statement of Changes in Equity (View)",
            kind: .equity,
            rows: [
                .init(id: .init(raw: "share_capital"), label: "Share Capital", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["30"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "reserves"), label: "Reserves", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["30"], includeLevel: nil, filterDirection: nil)]),
                .init(id: .init(raw: "retained"), label: "Retained Earnings", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includePrefixes: ["30"], includeLevel: nil, filterDirection: nil)])
            ]
        )
    }
}
