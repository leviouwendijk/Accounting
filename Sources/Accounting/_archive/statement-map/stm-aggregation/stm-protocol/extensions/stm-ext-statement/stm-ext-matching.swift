import Foundation

public extension StatementAggregating {
    func compileMatchers(for statement: StatementDef) throws -> [RowMatcher] {
        return statement.rows.map { row in
            // Pre-build one fast predicate per row. Union semantics: posting matches if any rule matches.
            let rules = row.rgs
            let pred: (NormalizedPosting) -> Bool = { p in
                for r in rules {
                    if matches(rule: r, posting: p) { return true }
                }
                return false
            }
            return RowMatcher(row: row, predicate: pred)
        }
    }

    @inline(__always)
    func matches(rule r: RGSMappingRule, posting p: NormalizedPosting) -> Bool {
        let hasCodes   = (r.includeCodes?.isEmpty == false)
        let hasPrefs   = (r.includePrefixes?.isEmpty == false)
        let hasLevel   = (r.includeLevel != nil)
        let hasOmslag  = (r.includeOmslagPrefixes?.isEmpty == false)   // ← NEW
        let hasDir     = (r.filterDirection != nil)

        guard hasCodes || hasPrefs || hasLevel || hasOmslag || hasDir else { return false }

        if hasCodes, let codes = r.includeCodes, !codes.contains(p.rgsCode) { return false }

        if hasPrefs, let prefs = r.includePrefixes {
            var ok = false; for pre in prefs where p.rgsCode.hasPrefix(pre) { ok = true; break }
            if !ok { return false }
        }

        if hasLevel, let lvl = r.includeLevel {
            guard let pl = p.rgsLevel, pl == lvl else { return false }
        }

        if hasOmslag, let oms = p.omslag, let op = r.includeOmslagPrefixes {
            var ok = false; for pre in op where oms.hasPrefix(pre) { ok = true; break }
            if !ok { return false }
        } else if hasOmslag {
            return false // rule wants omslag, posting has none
        }

        if hasDir, let dir = r.filterDirection {
            guard p.naturalSide == dir else { return false }
        }
        return true
    }
}
