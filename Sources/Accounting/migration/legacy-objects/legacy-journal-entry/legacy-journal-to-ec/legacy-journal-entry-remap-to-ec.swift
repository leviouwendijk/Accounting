import Foundation
import plate

public extension LegacyJournalEntry {
    func ecString(using translation: [LegacyMap]? = nil) -> String {
        let dict = (translation ?? LegacyTranslation.rgs_v3_8).byLegacyID
        return ecString(using: dict, overrides: [])
    }

    func ecString(
        using maps: [LegacyMap],
        overrides: [LegacyMapOverrideExceptions] = LegacyTranslation.rgs_v3_8_overrides,
    ) -> String {
        ecString(using: maps.byLegacyID, overrides: overrides)
    }

    /// Render with an explicit dictionary lookup.
    func ecString(
        using dict: [Int: LegacyMap],
        overrides: [LegacyMapOverrideExceptions],
        idOverride: Int? = nil
    ) -> String {
        var out: [String] = []
        func line(_ s: String) { out.append(s) }

        line("entry {")
        line("    id = \(idOverride ?? id)")
        if let d = date?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            line("    date = \(d)")
        } else {
            line("    // date missing; using inference upstream if desired")
        }
        line("")
        line("    sort \(type.convertForEC())")
        line("")
        if let d = description, let sd = secondaryDescription {
            line("    details {")
            line("        \(d)")
            line("        \(sd)")
            line("    }")
        } else if let d = description {
            line("    details {")
            line("        \(d)")
            line("    }")
        } else if let sd = secondaryDescription {
            line("    details {")
            line("        \(sd)")
            line("    }")
        }

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

        // // Debits
        // for (acctIDOpt, amtOpt) in debits {
        //     guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
        //     guard let m = dict[acctID] else { continue }
        //     line("")
        //     line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
        //     line("        debit = \(amt)")
        //     line("    }")
        // }

        // // Credits
        // for (acctIDOpt, amtOpt) in credits {
        //     guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
        //     guard let m = dict[acctID] else { continue }
        //     line("")
        //     line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
        //     line("        credit = \(amt)")
        //     line("    }")
        // }

        // START OF NEW
        let drInventoryIncrease: [String?] = [dr1InventoryIncrease, dr2InventoryIncrease, dr3InventoryIncrease, dr4InventoryIncrease, dr5InventoryIncrease]
        let crInventoryDecrease: [String?] = [cr1InventoryDecrease, cr2InventoryDecrease, cr3InventoryDecrease, cr4InventoryDecrease, cr5InventoryDecrease]

        // Debits
        for (i, pair) in debits.enumerated() {
            let (acctIDOpt, amtOpt) = pair
            guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
            guard let m = resolveMap(acctID: acctID, entryID: id, dict: dict, overrides: overrides) else { continue }
            line("")
            line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
            line("        debit = \(amt)")

            // --- NEW: inline inventory block (debits → add) ---
            if i < drInventoryIncrease.count {
                let add = parseInventoryCount(drInventoryIncrease[i])
                if let block = prepareInventoryBlock(add: add, remove: nil) {
                    line(block.indent(times: 2)) // keep indentation inside the `for {}` block
                }
            }

            line("    }")
        }

        // Credits
        for (i, pair) in credits.enumerated() {
            let (acctIDOpt, amtOpt) = pair
            guard let acctID = acctIDOpt, let amt = cleanedAmount(amtOpt) else { continue }
            guard let m = resolveMap(acctID: acctID, entryID: id, dict: dict, overrides: overrides) else { continue }
            line("")
            line("    for (\(cleanEntity(m.entity))) in (\(m.account)) {")
            line("        credit = \(amt)")

            // --- NEW: inline inventory block (credits → remove) ---
            if i < crInventoryDecrease.count {
                let rem = parseInventoryCount(crInventoryDecrease[i])
                if let block = prepareInventoryBlock(add: nil, remove: rem) {
                    line(block.indent(times: 2))
                }
            }

            line("    }")
        }
        // EO NEW


        let metadata = compileMetadata()

        if !metadata.isEmpty {
            line("")
            line("    metadata {")
            for i in metadata {
                line("        \(i.key) = \(i.value)")
            }
            line("    }")
        }

        line("}")

        if type == .closing {
            let closingOutput = commentOut(result: out)
            return closingOutput.joined(separator: "\n")
        } else {
            return out.joined(separator: "\n")
        }
    }

    private func commentOut(result: [String]) -> [String] {
        var closingOut: [String] = []
        let comment = "// "
        for i in result {
            let commentedOut = comment + i
            closingOut.append(commentedOut)
        }
        return closingOut
    }

    private func compileMetadata() -> [MetaObject] {
        func q(_ s: String) -> String {
            let esc = s
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
                .replacingOccurrences(of: "\n", with: "\\n")
            return "\"\(esc)\""
        }

        var metadata: [MetaObject] = []

        // store legacy entry id
        metadata.append(
            MetaObject(
                "legacy_journal_entry_id",
                String(id)
            )
        )

        // reference
        if let r = reference, !r.isEmpty {
            metadata.append(MetaObject("legacy_reference", q(r)))
        }

        // asset_item_id_1...5
        let assetItems: [Int?] = [assetItemId1, assetItemId2, assetItemId3, assetItemId4, assetItemId5]
        for (i, v) in assetItems.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_asset_item_id_\(i + 1)", String(v!)))
        }

        // dr_* inventory_increase (as strings; keep quoted)
        let drs: [String?] = [dr1InventoryIncrease, dr2InventoryIncrease, dr3InventoryIncrease, dr4InventoryIncrease, dr5InventoryIncrease]
        for (i, v) in drs.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_inventory_increase_\(i + 1)", q(v!)))
        }

        // cr_* inventory_decrease (as strings; keep quoted)
        let crs: [String?] = [cr1InventoryDecrease, cr2InventoryDecrease, cr3InventoryDecrease, cr4InventoryDecrease, cr5InventoryDecrease]
        for (i, v) in crs.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_inventory_decrease_\(i + 1)", q(v!)))
        }

        // related_bunq_transaction_1...5
        let bunqRefs: [Int?] = [
            relatedBunqTransaction1, relatedBunqTransaction2, relatedBunqTransaction3,
            relatedBunqTransaction4, relatedBunqTransaction5
        ]
        for (i, v) in bunqRefs.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_related_bunq_transaction_\(i + 1)", String(v!)))
        }

        // related_journal_entry_1...5
        let journalRefs: [Int?] = [
            relatedJournalEntry1, relatedJournalEntry2, relatedJournalEntry3,
            relatedJournalEntry4, relatedJournalEntry5
        ]
        for (i, v) in journalRefs.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_related_journal_entry_\(i + 1)", String(v!)))
        }

        // related_other_bank_transaction_1...5
        let otherBankRefs: [Int?] = [
            relatedOtherBankTransaction1, relatedOtherBankTransaction2, relatedOtherBankTransaction3,
            relatedOtherBankTransaction4, relatedOtherBankTransaction5
        ]
        for (i, v) in otherBankRefs.enumerated() where v != nil {
            metadata.append(MetaObject("legacy_related_other_bank_transaction_\(i + 1)", String(v!)))
        }

        return metadata
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

    private func resolveMap(
        acctID: Int,
        entryID: Int,
        dict: [Int: LegacyMap],
        overrides: [LegacyMapOverrideExceptions]
    ) -> LegacyMap? {
        if let hit = overrides.first(where: {
            $0.legacyEntryIds.contains(entryID) && $0.legacyMapOverride.legacyId == acctID
        }) {
            return hit.legacyMapOverride
        }
        return dict[acctID]
    }
}
