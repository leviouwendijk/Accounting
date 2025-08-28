import Foundation

public extension RGSAssembler {
    @inline(__always)
    static func classifyBalance(
        letter: String,
        bounds: AlphaBounds = .default
    ) -> RGSAssembleSection.Balance? {
        guard let c = letter.uppercased().unicodeScalars.first else { return nil }
        func u(_ s: String) -> UnicodeScalar? { s.uppercased().unicodeScalars.first }

        guard
            let A = u(bounds.assetsStart),
            let J = u(bounds.equityStart),
            let K = u(bounds.liabilitiesStart),
            let O = u(bounds.pAndLStart)
        else { return nil }

        // Assets: [A, J)
        if c >= A && c < J { return .assets }
        // Equity: [J, K)
        if c >= J && c < K { return .equity }
        // Liabilities: [K, O)
        if c >= K && c < O { return .liabilities }
        // P&L: [O, Z] — not returned here on purpose (we only bucket balance)
        return nil
    }

    /// Partition BALANCE totals into A/J/K sections by alphabetical SortingKey bands.
    /// Totals are built from **leaf** nodes only to avoid double-counting.
    static func balanceAlphaSections(
        totals: [Int: Decimal],
        maps: RGSAssemblerResult,
        bounds: AlphaBounds = .default
    ) throws -> BalanceAlphaSections {

        // Build parent set to detect leaves
        let parentSet = Set(maps.parentById.values)

        var totalsRaw: [RGSAssembleSection.Balance: Decimal] = [:]
        var idsBySection: [RGSAssembleSection.Balance: [Int]] = [:]

        for (id, amt) in totals where amt != 0 {
            // only leaves
            if parentSet.contains(id) { continue }
            // only balance nodes
            guard maps.kindById[id] == .balance else { continue }
            guard let key = maps.sortKeyById[id], let letter = firstLetterSegment(from: key) else {
                // skip nodes without proper sort key; could also throw if you prefer strictness
                continue
            }
            guard let sec = classifyBalance(letter: letter, bounds: bounds) else {
                // not A/J/K band (maybe P&L O..Z); ignore
                continue
            }
            totalsRaw[sec, default: 0] += amt
            idsBySection[sec, default: []].append(id)
        }

        return BalanceAlphaSections(totalsRaw: totalsRaw, leafIds: idsBySection)
    }
}
