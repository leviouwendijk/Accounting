import Foundation

public enum RootNodeClass: String, CaseIterable, Sendable {
    case asset, liability, equity, revenue, expense
}

public struct RootOverride: Sendable {
    public var toEquity: Set<String> = []
    public var toLiability: Set<String> = []
    public var toRevenue: Set<String> = []
    public var toExpense: Set<String> = []
    public init() {}
}

public extension RGSAccountAggregator {
    @inlinable
    func rootBucket(for family: FamilyKey) -> RootNodeClass {
        let n = family.value
        switch n {
        // Balance Sheet
        case 1000..<5000:   return .asset      // fixed assets
        case 5000..<7000:   return .equity     // equity (incl. drawings/privé)
        case 7000..<8000:   return .liability  // provisions
        case 8000..<10000:  return .liability  // long-term debt
        case 10000..<13000: return .asset      // cash & short-term securities
        case 13000..<16000: return .asset      // receivables
        case 16000..<18000: return .liability  // short-term & accruals
        case 30000..<36000: return .asset      // inventories & WIP

        // P&L
        case 40000..<80000: return .expense
        case 80000..<90000: return (n == 84000) ? .expense : .revenue
        case 90000..<92000: return .expense   // 91000 tax (IS)

        default:
            if n >= 40000 && n < 80000 { return .expense }
            if n >= 80000 && n < 90000 { return .revenue }
            return .expense
        }
    }

    /// Account-level override-aware classification.
    func rootBucket(for account: RGSAccount, override: RootOverride? = nil) -> RootNodeClass {
        if let ov = override {
            if ov.toEquity.contains(account.code)   { return .equity }
            if ov.toLiability.contains(account.code){ return .liability }
            if ov.toRevenue.contains(account.code)  { return .revenue }
            if ov.toExpense.contains(account.code)  { return .expense }
        }
        let w = account.code.count
        guard let n = Int(account.code), (w == 4 || w == 5) else { return .expense }
        let fam = _familyKey(for: n, width: w)
        return rootBucket(for: fam)
    }

    /// Group families by root for printing or statement building.
    func familiesGroupedByRoot() -> [RootNodeClass: [FamilyNode]] {
        var out: [RootNodeClass: [FamilyNode]] = [:]
        for fam in sortedFamilies() {
            out[rootBucket(for: fam.key), default: []].append(fam)
        }
        return out.mapValues { $0.sorted { $0.key.value < $1.key.value } }
    }
}
