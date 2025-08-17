import Foundation

public enum AggregationRole: Sendable {
    case posting       // operational: bank, expense, revenue, etc.
    case aggregation   // appropriation/derived: 97500, 97200, 98000 …
}

public struct AggregationPolicy: Sendable {
    /// Exact codes treated as aggregation/appropriation-only.
    public var aggregationCodes: Set<String> = ["97500", "97200", "98000"]
    /// Families that are typically appropriation/bridge (kept empty if you prefer exact-codes only).
    public var aggregationFamilies: Set<Int> = []
    public init(aggregationCodes: Set<String> = ["97500","97200","98000"],
                aggregationFamilies: Set<Int> = []) {
        self.aggregationCodes = aggregationCodes
        self.aggregationFamilies = aggregationFamilies
    }
}

public extension RGSAccount {
    func aggregationRole(policy: AggregationPolicy) -> AggregationRole {
        if policy.aggregationCodes.contains(self.code) { return .aggregation }
        if let n = Int(self.code) {
            let fam = (n / 1000) * 1000
            if policy.aggregationFamilies.contains(fam) { return .aggregation }
        }
        return .posting
    }
}
