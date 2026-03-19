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

// ARRAY EXTENSIONS
public extension Array where Element == LegacyJournalEntry {
    func ecFile(
        using maps: [LegacyMap] = LegacyTranslation.rgs_v3_8,
        overrides: [LegacyMapOverrideExceptions] = LegacyTranslation.rgs_v3_8_overrides,
        idProvider: ((LegacyJournalEntry) -> Int)? = nil,
        assetMappings: [Int: LegacyAssetMappingLike] = LegacyAssetMappings.rgs_v3_8
    ) -> String {
        ecFile(
            using: maps.byLegacyID,
            overrides: overrides,
            idProvider: idProvider,
            assetMappings: assetMappings
        )
    }

    func ecFile(
        using dict: [Int: LegacyMap],
        overrides: [LegacyMapOverrideExceptions] = LegacyTranslation.rgs_v3_8_overrides,
        idProvider: ((LegacyJournalEntry) -> Int)? = nil,
        assetMappings: [Int: LegacyAssetMappingLike] = LegacyAssetMappings.rgs_v3_8
    ) -> String {
        self.map { e in 
            e.ecString(
                using: dict,
                overrides: overrides,
                idOverride: idProvider?(e),
                assetMappings: assetMappings
            ) 
        }
        .joined(separator: "\n\n")
    }
}
