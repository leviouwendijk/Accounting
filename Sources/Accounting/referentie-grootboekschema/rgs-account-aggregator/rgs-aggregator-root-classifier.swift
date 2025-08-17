import Foundation

public enum RootNodeClass: String, CaseIterable, Sendable {
    case asset, liability, equity, revenue, expense, aggregated
}

public enum RootClassificationError: Error, CustomStringConvertible, Sendable {
    case nonNumeric(code: String)
    case wrongWidth(code: String, width: Int)
    case unknownFamily(FamilyKey)
    case unknownAccount(RGSAccount)

    public var description: String {
        switch self {
        case .nonNumeric(let c): return "Non-numeric account code: \(c)"
        case .wrongWidth(let c, let w): return "Wrong code width (\(w)) for \(c) — expected 4 or 5"
        case .unknownFamily(let f): return "Unknown family range: \(f.value) (width \(f.width))"
        case .unknownAccount(let a): return "Unknown account: \(a.code) \(a.label)"
        }
    }
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
    func rootBucket(for family: FamilyKey) throws -> RootNodeClass {
        let n = family.value
        switch n {
        // Balance Sheet
        case 1000..<5000:   return .asset
        case 5000..<7000:   return .equity
        case 7000..<8000:   return .liability
        case 8000..<10000:  return .liability
        case 10000..<13000: return .asset
        case 13000..<16000: return .asset
        case 16000..<18000: return .liability
        case 30000..<36000: return .asset

        // P&L
        case 40000..<80000: return .expense
        case 80000..<90000: return (n == 84000) ? .expense : .revenue
        case 90000..<92000: return .expense

        // Appropriation / Aggregation families (RGS)
        case 97000..<98100: return .aggregated   // 97000 (Aandeel derden), 98000 (Mutatie FOR)

        default:
            throw RootClassificationError.unknownFamily(family)
        }
    }

    func rootBucket(for account: RGSAccount, override: RootOverride? = nil) throws -> RootNodeClass {
        if let ov = override {
            if ov.toEquity.contains(account.code)    { return .equity }
            if ov.toLiability.contains(account.code) { return .liability }
            if ov.toRevenue.contains(account.code)   { return .revenue }
            if ov.toExpense.contains(account.code)   { return .expense }
        }

        let w = account.code.count
        guard let n = Int(account.code) else { throw RootClassificationError.nonNumeric(code: account.code) }
        guard w == 4 || w == 5 else { throw RootClassificationError.wrongWidth(code: account.code, width: w) }

        let fam = _familyKey(for: n, width: w)
        return try rootBucket(for: fam)
    }

    func familiesGroupedByRoot() throws -> [RootNodeClass: [FamilyNode]] {
        var out: [RootNodeClass: [FamilyNode]] = [:]
        for fam in sortedFamilies() {
            let bucket = try rootBucket(for: fam.key)
            out[bucket, default: []].append(fam)
        }
        return out.mapValues { $0.sorted { $0.key.value < $1.key.value } }
    }
}
