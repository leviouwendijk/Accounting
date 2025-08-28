import Foundation

public enum StatementLibrary {
    // Balance Sheet using explicit codes you showed
    public static func balanceIFRS(materiality: Decimal = 0) -> StatementDef {
        StatementDef(
            name: "IFRS – Balance Sheet",
            kind: .balance,
            rows: [
                .init(id: .init(raw: "assets"), label: "Assets", kind: .balance,
                      materialityThreshold: materiality,
                      rgs: [.init(includeCodes: ["BLimBanRba", "BVrdGehVoo"], includePrefixes: nil, includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "equity"), label: "Equity", kind: .balance,
                      materialityThreshold: 0,
                      rgs: [.init(includeCodes: [/* put one equity RGS code you have */], includePrefixes: nil, includeLevel: nil,  includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "liabilities"), label: "Liabilities", kind: .balance,
                      materialityThreshold: 0,
                      rgs: [.init(includeCodes: [/* one liability code */], includePrefixes: nil, includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)])
            ]
        )
    }

    // Income Statement using explicit codes you showed
    public static func incomeStatementIFRS(materiality: Decimal = 0) -> StatementDef {
        StatementDef(
            name: "IFRS – Income Statement",
            kind: .income,
            rows: [
                .init(id: .init(raw: "revenue"), label: "Revenue", kind: .income,
                      materialityThreshold: materiality,
                      rgs: [.init(includeCodes: ["WOmzNodOdh","WOmzNopOlh"], includePrefixes: nil, includeLevel: nil,  includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "cogs_expenses"), label: "COGS/Expenses", kind: .income,
                      materialityThreshold: materiality,
                      rgs: [.init(includeCodes: ["WKprKvgKvg"], includePrefixes: nil, includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)])
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
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["40","50","60","61","62"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "investing"), label: "Cash from Investing Activities", kind: .cash,
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["12"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "financing"), label: "Cash from Financing Activities", kind: .cash,
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["30"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)])
            ]
        )
    }

    public static func equityView(materiality: Decimal = 0) -> StatementDef {
        StatementDef(
            name: "IFRS – Statement of Changes in Equity (View)",
            kind: .equity,
            rows: [
                .init(id: .init(raw: "share_capital"), label: "Share Capital", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["30"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "reserves"), label: "Reserves", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["30"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)]),
                .init(id: .init(raw: "retained"), label: "Retained Earnings", kind: .equity,
                      materialityThreshold: materiality, rgs: [.init(includeCodes: [], includePrefixes: ["30"], includeLevel: nil, includeOmslagPrefixes: [], filterDirection: nil)])
            ]
        )
    }
}
