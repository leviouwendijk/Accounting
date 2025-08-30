import Foundation
import plate

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
