import Foundation
import plate

public extension Sequence where Element == LegacyMap {
    var byLegacyID: [Int: LegacyMap] {
        var dict: [Int: LegacyMap] = [:]
        dict.reserveCapacity(256)
        for m in self { dict[m.legacyId] = m }
        return dict
    }
}

public extension Array where Element == LegacyJournalEntry {
    func ecFile(
        using maps: [LegacyMap] = LegacyTranslation.rgs_v3_8,
        overrides: [LegacyMapOverrideExceptions] = LegacyTranslation.rgs_v3_8_overrides
    ) -> String {
        ecFile(using: maps.byLegacyID, overrides: overrides)
    }

    func ecFile(
        using dict: [Int: LegacyMap],
        overrides: [LegacyMapOverrideExceptions]
    ) -> String {
        self.map { $0.ecString(using: dict, overrides: overrides) }
        .joined(separator: "\n\n")
    }
}
