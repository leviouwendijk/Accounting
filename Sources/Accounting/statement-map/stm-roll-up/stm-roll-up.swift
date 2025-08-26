import Foundation

public enum RollupMode {
    case perAccount              // one row per account (label = account.label)
    case byExactOmslag           // one row per omslag string (label picked from a representative account)
}

public struct DefaultFromAccounts {
    public static func balanceDetail(from store: AccountStore,
                                     mode: RollupMode = .perAccount,
                                     materiality: Decimal = 0) -> StatementDef {
        switch mode {
        case .perAccount:
            let rows: [StatementRowDef] = store.all.map { acc in
                let lbl = acc.label.trimmingCharacters(in: .whitespacesAndNewlines)
                let rgs = acc.identifiers.rgs.isEmpty ? acc.code : acc.identifiers.rgs
                return StatementRowDef(
                    id: .init(raw: "acc.\(acc.code)"),
                    label: lbl,
                    kind: .balance,
                    materialityThreshold: materiality,
                    rgs: [.init(includeCodes: [rgs],
                                includePrefixes: nil,
                                includeLevel: acc.level,
                                includeOmslagPrefixes: nil,
                                filterDirection: nil)]
                )
            }
            return StatementDef(name: "Balance – Detail (per account)", kind: .balance, rows: rows)

        case .byExactOmslag:
            // group accounts by identical omslag code, use a decent label per group
            let groups = Dictionary(grouping: store.all) { $0.identifiers.omslag ?? "__NO_OMSLAG__" }
            let rows: [StatementRowDef] = groups.map { (omslag, accs) in
                let chosenLabel = accs.first?.label ?? (omslag == "__NO_OMSLAG__" ? "Other (no omslag)" : omslag)
                let rule = RGSMappingRule(
                    includeCodes: nil, includePrefixes: nil, includeLevel: nil,
                    includeOmslagPrefixes: omslag == "__NO_OMSLAG__" ? nil : [omslag],
                    filterDirection: nil
                )
                return StatementRowDef(
                    id: .init(raw: "omslag.\(omslag)"),
                    label: chosenLabel,
                    kind: .balance,
                    materialityThreshold: materiality,
                    rgs: [rule]
                )
            }
            return StatementDef(name: "Balance – Detail (per omslag)", kind: .balance, rows: rows)
        }
    }
}
