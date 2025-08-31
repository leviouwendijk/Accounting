import Foundation

// Handy mapping for "legacyAssetId -> preferred entity alias/unit + expense account"
public struct LegacyAssetMapping: Sendable, Codable {
    /// Entity (root) alias, e.g. "macbook"
    public let alias: String
    /// Unit alias, e.g. "levi_air_m2"
    public let unit: String
    /// Optional depreciation expense account code, e.g. "WAfsAmvBei"
    public let account: String?

    public init(alias: String, unit: String, account: String? = nil) {
        self.alias = alias
        self.unit = unit
        self.account = account
    }
}

public extension LegacyAssetItem {
    /// Convenience overload: look up alias/unit/account by legacy asset id.
    /// Falls back to the main `ecString(…)` defaults when a field is missing.
    func ecString(
        mappingById: [Int: LegacyAssetMapping],
        className: String = "objects",
        family: String = "usable",
        rootAlias: String? = nil,
        unitAlias: String? = nil,
        depreciationExpenseAccountCode: String? = nil
    ) -> String {
        let m = mappingById[id]
        return ecString(
            className: className,
            family: family,
            rootAlias: m?.alias ?? rootAlias,
            unitAlias: m?.unit ?? unitAlias,
            depreciationExpenseAccountCode: m?.account ?? depreciationExpenseAccountCode
        )
    }

    /// Emit an `.ec` entity block with a depreciation config (4-space indents).
    /// Matches the reference DSL shape you posted.
    func ecString(
        className: String = "objects",
        family: String = "usable",
        rootAlias: String? = nil,
        unitAlias: String? = nil,
        depreciationExpenseAccountCode: String? = nil
    ) -> String {

        // --- helpers ---
        struct W {
            var s = ""
            var lvl = 0
            mutating func line(_ t: String = "") {
                s += String(repeating: " ", count: 4 * lvl) + t + "\n"
            }
            mutating func open(_ h: String) { line(h + " {"); lvl += 1 }
            mutating func close() { lvl -= 1; line("}") }
        }

        @inline(__always)
        func ymd(_ iso: String?) -> (y: Int?, m: Int?, d: Int?) {
            guard let iso, !iso.isEmpty else { return (nil, nil, nil) }
            let parts = iso.split(separator: "-").map { String($0) }
            let y = parts.count > 0 ? Int(parts[0]) : nil
            let m = parts.count > 1 ? Int(parts[1]) : nil
            let d = parts.count > 2 ? Int(parts[2]) : nil
            return (y, m, d)
        }

        @inline(__always)
        func emit(_ w: inout W, key: String, _ val: String?) {
            guard let v = val, !v.isEmpty else { return }
            w.line("\(key) = \(v)")
        }

        // --- derive aliases (match your reference) ---
        let root = rootAlias ?? "asset_placeholder"          // placeholder policy
        let unit = unitAlias ?? "legacy_asset_id_\(id)"       // <- matches your snippet

        // --- build ---
        var w = W()
        w.open("entity")
        w.line("use alias \(root)")
        w.line("")
        w.open("unit")
        w.line("use alias \(unit)")
        if let desc = description, !desc.isEmpty {
            w.line("")
            w.open("details")
            w.line(desc)
            w.close()
        }


        w.line("")
        // metadata { legacy_* = … }
        w.open("metadata")
        w.line("// legacy data object")

        // REQUIRED/IDs
        w.line("legacy_asset_item_id = \(id)")
        if let pa = assetPrimaryAccountId { w.line("legacy_primary_account_id = \(pa)") }
        if let je = journalEntryId { w.line("legacy_journal_entry_id = \(je)") }

        // NUMERICS (stringly; preserve raw export)
        emit(&w, key: "legacy_asset_cost", assetCost)
        emit(&w, key: "legacy_useful_life", usefulLife)
        emit(&w, key: "legacy_residual_value", residualValue)
        emit(&w, key: "legacy_residual_value_pct", residualValuePercentage)

        // FLAGS/ENUMS
        if let t = tangibility { w.line("legacy_tangibility = \(t.rawValue)") }
        if let m = writeOffMethod {
            w.line("legacy_write_off_method_raw = \(m.rawValue)")
            w.line("legacy_write_off_method_token = \(m.convertForEC())") // straight_line/ddb/syd/uop(full token)
        }

        // DATES
        if let cd = commissionDate, !cd.isEmpty {
            w.line("legacy_commission_date = \(cd)")
        }

        w.close() // metadata

        w.line("")
        // depreciation { … }
        w.open("depreciation")

        if let acc = depreciationExpenseAccountCode, !acc.isEmpty {
            w.line("account = \(acc)")
            w.line("")
        }

        // method
        if let meth = writeOffMethod {
            w.line("method = \(meth.convertForEC())")
        } else {
            w.line("method = straight_line")
        }
        w.line("")

        // valuation
        w.open("valuation")
        w.open("acquisition_cost")
        emit(&w, key: "direct", assetCost ?? "0.00")
        w.line("indirect = 0.00")
        w.close() // acquisition_cost
        // w.line("// capital_expenditures {} // added by entries?")
        w.close() // valuation
        w.line("")

        // commission_date { y/m/d }
        let (y, m, d) = ymd(commissionDate)
        w.open("commission_date")
        // if let y { w.line("year = \(String(format: "%04d", y))") }
        // if let m { w.line("month = \(String(format: "%02d", m))") }
        // if let d { w.line("day = \(String(format: "%02d", d))") }
        if let y { w.line("year = \(y)") }
        if let m { w.line("month = \(m)") }
        if let d { w.line("day = \(d)") }
        w.close()
        w.line("")


        // useful_life
        emit(&w, key: "useful_life", usefulLife ?? "0.00")
        w.line("")

        // residual_value { percentage / value }
        w.open("residual_value")
        if let pct = residualValuePercentage, !pct.isEmpty {
            w.line("percentage = \(pct)")
        }
        if let val = residualValue, !val.isEmpty {
            w.line("// value = \(val)  // optional; derive or fix during reconciliation")
        }
        w.close()

        w.close() // depreciation
        w.close() // unit
        w.close() // entity
        return w.s
    }
}
