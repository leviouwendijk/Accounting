import Foundation
import plate

public struct AggregatorValidationReport: Sendable {
    public var nonNumeric: [RGSAccount]          // code not numeric
    public var wrongWidth: [RGSAccount]          // code length ≠ 4/5
    public var unclassifiedRoot: [RGSAccount]    // failed root classification (strict mode)
    public var orphans: [RGSAccount]             // 4/5-digit that didn’t land in aggregator families
    public var duplicates: [String]              // duplicate codes detected in input
    public var aggregationOnly: [RGSAccount]     // role == .aggregation (informational)

    public var hasErrors: Bool {
        return !nonNumeric.isEmpty || !wrongWidth.isEmpty || !unclassifiedRoot.isEmpty || !orphans.isEmpty || !duplicates.isEmpty
    }

    public func printable() -> String {
        var s = "Validation report\n"
        s += hasErrors ? "ERROR\n".ansi(.red) : "SUCCESS\n".ansi(.green)
        func block(_ title: String, _ rows: [String]) {
            guard !rows.isEmpty else { return }
            s += "— \(title):\n"
            for r in rows { s += "   " + r + "\n" }
        }
        block("Non-numeric codes", nonNumeric.map { "\($0.code) \($0.label)" })
        block("Wrong width (≠ 4/5)", wrongWidth.map { "\($0.code) \($0.label)" })
        block("Unclassified Root", unclassifiedRoot.map { "\($0.code) \($0.label)" })
        block("Orphans (not in aggregator)", orphans.map { "\($0.code) \($0.label)" })
        block("Duplicate codes", duplicates)
        block("Aggregation-only (info)", aggregationOnly.map { "\($0.code) \($0.label)" })
        return s
    }
}

public enum AggregatorValidationError: Error, CustomStringConvertible, Sendable {
    case failed(AggregatorValidationReport)
    public var description: String {
        switch self {
        case .failed(let r): return r.printable()
        }
    }
}

public extension RGSAccountAggregator {

    /// Classify every account into (Root, Role), and verify full coverage.
    /// - Parameters:
    ///   - accounts: the full RGS set you built the aggregator from
    ///   - overrides: optional account-level root overrides
    ///   - aggPolicy: marks “aggregation/derived” codes (e.g. 97500/97200/98000)
    ///   - strictFamilies: if true, treat unknown family ranges as errors (no silent fallbacks)
    /// - Throws: AggregatorValidationError if anything is missing/misclassified
    func validateCoverage(
        accounts: [RGSAccount],
        overrides: RootOverride? = nil,
        aggPolicy: AggregationPolicy = .init(),
        strictFamilies: Bool = true
    ) throws -> AggregatorValidationReport {

        // 0) detect duplicates up-front
        var seen = Set<String>()
        var dups = [String]()
        for a in accounts {
            if !seen.insert(a.code).inserted { dups.append(a.code) }
        }

        // 1) bucket helper
        func tryRoot(_ a: RGSAccount) -> RootNodeClass? {
            // In strict mode, we want to catch “unknown family” instead of defaulting to .expense.
            // We do this by recomputing the family and verifying it hits one of our explicit ranges.
            if strictFamilies {
                guard let n = Int(a.code) else { return nil }
                let w = a.code.count
                guard w == 4 || w == 5 else { return nil }
                let famKey = _familyKey(for: n, width: w)
                // Probe: call the family classifier and accept whatever it returns (since ranges are explicit).
                return rootBucket(for: famKey)
            } else {
                return rootBucket(for: a, override: overrides)
            }
        }

        // 2) classify all accounts & gather issues
        var nonNumeric = [RGSAccount]()
        var wrongWidth = [RGSAccount]()
        var unclassified = [RGSAccount]()
        var aggregationOnly = [RGSAccount]()

        // Build a set of all codes the aggregator actually contains
        var contained = Set<String>()
        for fam in families.values {
            for l2 in fam.headersL2 { contained.insert(l2.code) }
            for sub in fam.subclasses.values {
                for l3 in sub.headersL3 { contained.insert(l3.code) }
                for l4 in sub.leavesL4 { contained.insert(l4.code) }
            }
        }

        // Check each account
        for a in accounts {
            // numeric?
            guard let _ = Int(a.code) else {
                nonNumeric.append(a); continue
            }
            // width?
            let w = a.code.count
            guard w == 4 || w == 5 else {
                wrongWidth.append(a); continue
            }
            // root?
            guard let _ = tryRoot(a) else {
                unclassified.append(a); continue
            }

            // role (posting/aggregation)
            if a.aggregationRole(policy: aggPolicy) == .aggregation {
                aggregationOnly.append(a)
            }
        }

        // 3) orphans: 4/5-digit accounts not present in aggregator structure
        let fourFive = accounts.filter { $0.code.allSatisfy(\.isNumber) && ($0.code.count == 4 || $0.code.count == 5) }
        let orphans = fourFive.filter { !contained.contains($0.code) }

        let report = AggregatorValidationReport(
            nonNumeric: nonNumeric,
            wrongWidth: wrongWidth,
            unclassifiedRoot: unclassified,
            orphans: orphans,
            duplicates: dups,
            aggregationOnly: aggregationOnly
        )

        if report.hasErrors { throw AggregatorValidationError.failed(report) }
        return report
    }
}
