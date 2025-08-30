import Foundation
import plate
import Extensions

public typealias LegacyJournalEntriesPage = ExportPage<LegacyJournalEntry>

public enum LegacyJournalEntryType: String, RawRepresentable, Sendable, Codable, StringParsableEnum {
    case regular = "Regular Entry"
    case adjusting = "Adjusting Entry"
    case closing = "Closing Entry"

    public func convertForEC() -> String {
        switch self {
        case .regular:
            return "regular"
        case .adjusting:
            return "adjusting"
        case .closing:
            return "closing_deprecated"
        }
    }
}

public struct LegacyJournalEntry: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public let id: Int

    public let date: String?
    public let createdAt: String?
    public let type: LegacyJournalEntryType

    public let description: String?
    public let secondaryDescription: String?
    public let reference: String?

    // Debit accounts + amounts
    public let debitAccount1: Int?
    public let debitAccount2: Int?
    public let debitAccount3: Int?
    public let debitAccount4: Int?
    public let debitAccount5: Int?

    public let debitAmount1: String?
    public let debitAmount2: String?
    public let debitAmount3: String?
    public let debitAmount4: String?
    public let debitAmount5: String?

    // Credit accounts + amounts
    public let creditAccount1: Int?
    public let creditAccount2: Int?
    public let creditAccount3: Int?
    public let creditAccount4: Int?
    public let creditAccount5: Int?

    public let creditAmount1: String?
    public let creditAmount2: String?
    public let creditAmount3: String?
    public let creditAmount4: String?
    public let creditAmount5: String?

    // Inventory movements (legacy flags/counters)
    public let dr1InventoryIncrease: String?
    public let dr2InventoryIncrease: String?
    public let dr3InventoryIncrease: String?
    public let dr4InventoryIncrease: String?
    public let dr5InventoryIncrease: String?

    public let cr1InventoryDecrease: String?
    public let cr2InventoryDecrease: String?
    public let cr3InventoryDecrease: String?
    public let cr4InventoryDecrease: String?
    public let cr5InventoryDecrease: String?

    // Asset item links
    public let assetItemId1: Int?
    public let assetItemId2: Int?
    public let assetItemId3: Int?
    public let assetItemId4: Int?
    public let assetItemId5: Int?

    // Cross-links
    public let relatedBunqTransaction1: Int?
    public let relatedBunqTransaction2: Int?
    public let relatedBunqTransaction3: Int?
    public let relatedBunqTransaction4: Int?
    public let relatedBunqTransaction5: Int?

    public let relatedJournalEntry1: Int?
    public let relatedJournalEntry2: Int?
    public let relatedJournalEntry3: Int?
    public let relatedJournalEntry4: Int?
    public let relatedJournalEntry5: Int?

    public let relatedOtherBankTransaction1: Int?
    public let relatedOtherBankTransaction2: Int?
    public let relatedOtherBankTransaction3: Int?
    public let relatedOtherBankTransaction4: Int?
    public let relatedOtherBankTransaction5: Int?

    public init(
        id: Int,
        date: String?,
        createdAt: String?,
        type: String,
        description: String?,
        secondaryDescription: String?,
        reference: String?,
        debitAccount1: Int?, debitAccount2: Int?, debitAccount3: Int?, debitAccount4: Int?, debitAccount5: Int?,
        debitAmount1: String?, debitAmount2: String?, debitAmount3: String?, debitAmount4: String?, debitAmount5: String?,
        creditAccount1: Int?, creditAccount2: Int?, creditAccount3: Int?, creditAccount4: Int?, creditAccount5: Int?,
        creditAmount1: String?, creditAmount2: String?, creditAmount3: String?, creditAmount4: String?, creditAmount5: String?,
        dr1InventoryIncrease: String?, dr2InventoryIncrease: String?, dr3InventoryIncrease: String?, dr4InventoryIncrease: String?, dr5InventoryIncrease: String?,
        cr1InventoryDecrease: String?, cr2InventoryDecrease: String?, cr3InventoryDecrease: String?, cr4InventoryDecrease: String?, cr5InventoryDecrease: String?,
        assetItemId1: Int?, assetItemId2: Int?, assetItemId3: Int?, assetItemId4: Int?, assetItemId5: Int?,
        relatedBunqTransaction1: Int?, relatedBunqTransaction2: Int?, relatedBunqTransaction3: Int?, relatedBunqTransaction4: Int?, relatedBunqTransaction5: Int?,
        relatedJournalEntry1: Int?, relatedJournalEntry2: Int?, relatedJournalEntry3: Int?, relatedJournalEntry4: Int?, relatedJournalEntry5: Int?,
        relatedOtherBankTransaction1: Int?, relatedOtherBankTransaction2: Int?, relatedOtherBankTransaction3: Int?, relatedOtherBankTransaction4: Int?, relatedOtherBankTransaction5: Int?
    ) throws {
        self.id = id
        self.date = date
        self.createdAt = createdAt
        self.type = try LegacyJournalEntryType.parse(from: type)
        self.description = description
        self.secondaryDescription = secondaryDescription
        self.reference = reference

        self.debitAccount1 = debitAccount1
        self.debitAccount2 = debitAccount2
        self.debitAccount3 = debitAccount3
        self.debitAccount4 = debitAccount4
        self.debitAccount5 = debitAccount5

        self.debitAmount1 = debitAmount1
        self.debitAmount2 = debitAmount2
        self.debitAmount3 = debitAmount3
        self.debitAmount4 = debitAmount4
        self.debitAmount5 = debitAmount5

        self.creditAccount1 = creditAccount1
        self.creditAccount2 = creditAccount2
        self.creditAccount3 = creditAccount3
        self.creditAccount4 = creditAccount4
        self.creditAccount5 = creditAccount5

        self.creditAmount1 = creditAmount1
        self.creditAmount2 = creditAmount2
        self.creditAmount3 = creditAmount3
        self.creditAmount4 = creditAmount4
        self.creditAmount5 = creditAmount5

        self.dr1InventoryIncrease = dr1InventoryIncrease
        self.dr2InventoryIncrease = dr2InventoryIncrease
        self.dr3InventoryIncrease = dr3InventoryIncrease
        self.dr4InventoryIncrease = dr4InventoryIncrease
        self.dr5InventoryIncrease = dr5InventoryIncrease

        self.cr1InventoryDecrease = cr1InventoryDecrease
        self.cr2InventoryDecrease = cr2InventoryDecrease
        self.cr3InventoryDecrease = cr3InventoryDecrease
        self.cr4InventoryDecrease = cr4InventoryDecrease
        self.cr5InventoryDecrease = cr5InventoryDecrease

        self.assetItemId1 = assetItemId1
        self.assetItemId2 = assetItemId2
        self.assetItemId3 = assetItemId3
        self.assetItemId4 = assetItemId4
        self.assetItemId5 = assetItemId5

        self.relatedBunqTransaction1 = relatedBunqTransaction1
        self.relatedBunqTransaction2 = relatedBunqTransaction2
        self.relatedBunqTransaction3 = relatedBunqTransaction3
        self.relatedBunqTransaction4 = relatedBunqTransaction4
        self.relatedBunqTransaction5 = relatedBunqTransaction5

        self.relatedJournalEntry1 = relatedJournalEntry1
        self.relatedJournalEntry2 = relatedJournalEntry2
        self.relatedJournalEntry3 = relatedJournalEntry3
        self.relatedJournalEntry4 = relatedJournalEntry4
        self.relatedJournalEntry5 = relatedJournalEntry5

        self.relatedOtherBankTransaction1 = relatedOtherBankTransaction1
        self.relatedOtherBankTransaction2 = relatedOtherBankTransaction2
        self.relatedOtherBankTransaction3 = relatedOtherBankTransaction3
        self.relatedOtherBankTransaction4 = relatedOtherBankTransaction4
        self.relatedOtherBankTransaction5 = relatedOtherBankTransaction5
    }

    enum CodingKeys: String, CodingKey {
        case id, date, type, description, reference
        case createdAt = "created_at"
        case secondaryDescription = "secondary_description"

        case debitAccount1 = "debit_account_1"
        case debitAccount2 = "debit_account_2"
        case debitAccount3 = "debit_account_3"
        case debitAccount4 = "debit_account_4"
        case debitAccount5 = "debit_account_5"

        case debitAmount1 = "debit_amount_1"
        case debitAmount2 = "debit_amount_2"
        case debitAmount3 = "debit_amount_3"
        case debitAmount4 = "debit_amount_4"
        case debitAmount5 = "debit_amount_5"

        case creditAccount1 = "credit_account_1"
        case creditAccount2 = "credit_account_2"
        case creditAccount3 = "credit_account_3"
        case creditAccount4 = "credit_account_4"
        case creditAccount5 = "credit_account_5"

        case creditAmount1 = "credit_amount_1"
        case creditAmount2 = "credit_amount_2"
        case creditAmount3 = "credit_amount_3"
        case creditAmount4 = "credit_amount_4"
        case creditAmount5 = "credit_amount_5"

        case dr1InventoryIncrease = "dr_1_inventory_increase"
        case dr2InventoryIncrease = "dr_2_inventory_increase"
        case dr3InventoryIncrease = "dr_3_inventory_increase"
        case dr4InventoryIncrease = "dr_4_inventory_increase"
        case dr5InventoryIncrease = "dr_5_inventory_increase"

        case cr1InventoryDecrease = "cr_1_inventory_decrease"
        case cr2InventoryDecrease = "cr_2_inventory_decrease"
        case cr3InventoryDecrease = "cr_3_inventory_decrease"
        case cr4InventoryDecrease = "cr_4_inventory_decrease"
        case cr5InventoryDecrease = "cr_5_inventory_decrease"

        case assetItemId1 = "asset_item_id_1"
        case assetItemId2 = "asset_item_id_2"
        case assetItemId3 = "asset_item_id_3"
        case assetItemId4 = "asset_item_id_4"
        case assetItemId5 = "asset_item_id_5"

        case relatedBunqTransaction1 = "related_bunq_transaction_1"
        case relatedBunqTransaction2 = "related_bunq_transaction_2"
        case relatedBunqTransaction3 = "related_bunq_transaction_3"
        case relatedBunqTransaction4 = "related_bunq_transaction_4"
        case relatedBunqTransaction5 = "related_bunq_transaction_5"

        case relatedJournalEntry1 = "related_journal_entry_1"
        case relatedJournalEntry2 = "related_journal_entry_2"
        case relatedJournalEntry3 = "related_journal_entry_3"
        case relatedJournalEntry4 = "related_journal_entry_4"
        case relatedJournalEntry5 = "related_journal_entry_5"

        case relatedOtherBankTransaction1 = "related_other_bank_transaction_1"
        case relatedOtherBankTransaction2 = "related_other_bank_transaction_2"
        case relatedOtherBankTransaction3 = "related_other_bank_transaction_3"
        case relatedOtherBankTransaction4 = "related_other_bank_transaction_4"
        case relatedOtherBankTransaction5 = "related_other_bank_transaction_5"
    }
}

public enum LegacyIDsFilterType: Sendable, Codable {
    case used
    case unused
}

extension Array where Element == LegacyJournalEntry {
    public func filtering(for type: LegacyIDsFilterType, until n: Int) -> [Int] {
        guard n > 0 else { return [] }

        let used: Set<Int> = Set(self.flatMap { e in
            [
                e.debitAccount1, e.debitAccount2, e.debitAccount3, e.debitAccount4, e.debitAccount5,
                e.creditAccount1, e.creditAccount2, e.creditAccount3, e.creditAccount4, e.creditAccount5
            ].compactMap { $0 }
        })

        let usedInRange: Set<Int> = used.filter { 1...n ~= $0 }

        switch type {
        case .used:
            return usedInRange.sorted()

        case .unused:
            var unused: [Int] = []
            unused.reserveCapacity(n - usedInRange.count)

            for i in 1...n where !used.contains(i) {
                unused.append(i)
            }
            return unused
        }
    }
}
