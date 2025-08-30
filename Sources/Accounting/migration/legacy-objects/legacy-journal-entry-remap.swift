import Foundation
import plate

public extension LegacyJournalEntry {
    /// Render this journal entry to `.ec` text using a legacyId → LegacyMap lookup.
    /// You can pass either an array of maps or nothing (defaults to LegacyTranslation.rgs_v3_8).
    func ecString(using translation: [LegacyMap]? = nil) -> String {
        let dict = (translation ?? LegacyTranslation.rgs_v3_8).byLegacyID
        return ecString(using: dict)
    }

    /// Render with an explicit dictionary lookup.
    func ecString(using dict: [Int: LegacyMap]) -> String {
        var out: [String] = []
        func line(_ s: String) { out.append(s) }

        line("entry {")
        line("    id = \(id)")
        if let d = date?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            line("    date = \(d)")
        } else {
            line("    // date missing; using inference upstream if desired")
        }
        line("    sort \(type.convertForEC())")

        let debits: [(Int?, String?)] = [
            (debitAccount1, debitAmount1),
            (debitAccount2, debitAmount2),
            (debitAccount3, debitAmount3),
            (debitAccount4, debitAmount4),
            (debitAccount5, debitAmount5),
        ]
        let credits: [(Int?, String?)] = [
            (creditAccount1, creditAmount1),
            (creditAccount2, creditAmount2),
            (creditAccount3, creditAmount3),
            (creditAccount4, creditAmount4),
            (creditAccount5, creditAmount5),
        ]

        // Debits
        for (acctIDOpt, amtOpt) in debits {
            guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
            guard let m = dict[acctID] else { continue }
            line("")
            line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
            line("        debit = \(amt)")
            line("    }")
        }

        // Credits
        for (acctIDOpt, amtOpt) in credits {
            guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
            guard let m = dict[acctID] else { continue }
            line("")
            line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
            line("        credit = \(amt)")
            line("    }")
        }

        line("}")
        return out.joined(separator: "\n")
    }

    // Amount sanitizer
    private func cleanedAmount(_ s: String?) -> String? {
        guard var t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        if t.contains(",") { t = t.replacingOccurrences(of: ",", with: ".") }
        if let dec = Decimal(string: t, locale: Locale(identifier: "en_US_POSIX")) {
            var d = dec, rounded = Decimal()
            NSDecimalRound(&rounded, &d, 2, .plain)
            return NSDecimalNumber(decimal: rounded).stringValue
        }
        return t
    }

    private func cleanEntity(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public extension Sequence where Element == LegacyMap {
    /// legacyId → LegacyMap
    var byLegacyID: [Int: LegacyMap] {
        var dict: [Int: LegacyMap] = [:]
        dict.reserveCapacity(256)
        for m in self { dict[m.legacyId] = m }
        return dict
    }
}

public extension Array where Element == LegacyJournalEntry {
    /// Page → `.ec` text (array input)
    func ecFile(using maps: [LegacyMap] = LegacyTranslation.rgs_v3_8) -> String {
        ecFile(using: maps.byLegacyID)
    }

    /// Page → `.ec` text (dict input)
    func ecFile(using dict: [Int: LegacyMap]) -> String {
        self.map { $0.ecString(using: dict) }.joined(separator: "\n\n")
    }
}
