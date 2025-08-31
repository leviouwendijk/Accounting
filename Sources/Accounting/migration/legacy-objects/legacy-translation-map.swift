import Foundation

public struct LegacyMap: Sendable, Codable {
    public let legacyId: Int // primary account
    public let legacyName: String // for context quick look
    public let account: String // -> AccountRef -> AccountKey / RGSNode?
    public let entity: String // -> EntityRef -> EntityKey
    
    public init(
        legacyId: Int,
        legacyName: String,
        account: String,
        entity: String
    ) {
        self.legacyId = legacyId
        self.legacyName = legacyName
        self.account = account
        self.entity = entity
    }

    public init(
        _ legacyId: Int,
        _ legacyName: String,
        _ RGSAccountIdentifier: String, // rgs code, prepare for `in (<rgs string>)`
        _ localEntity: String // infer from alias level, prepare as renderable for entries `for (<entity>)`, anyway
    ) {
        self.legacyId = legacyId
        self.legacyName = legacyName
        self.account = RGSAccountIdentifier
        self.entity = localEntity
    }
}

public struct LegacyMapOverrideExceptions: Sendable, Codable {
    public let legacyEntryIds: [Int]
    public let legacyMapOverride: LegacyMap
    
    public init(
        legacyEntryIds: [Int],
        legacyMapOverride: LegacyMap
    ) {
        self.legacyEntryIds = legacyEntryIds
        self.legacyMapOverride = legacyMapOverride
    }
}

public enum LegacyTranslation {
    // (2025/08/30)
    //
    // > ~ $ legacy primary unused                                                                         @levi-m2 [12:15:56]
    // Unused:
    //  [4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 17, 18, 20, 21, 25, 26, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 46, 47, 49, 52, 53, 56, 57, 60, 61, 62, 66, 68, 69, 70, 71, 72, 73, 74, 75, 80, 81, 82, 83, 84, 85, 86, 88, 90, 93, 94, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 141, 142, 143, 144, 147, 149, 153, 154, 155, 156, 157, 158, 159, 161, 162, 163, 169, 172, 180, 182, 185, 186, 187, 189, 191, 194, 195, 196, 197, 199, 200, 201, 205, 214, 218, 219, 220, 221, 222, 223, 224]
    // Count:
    //  143

    // Used:
    //  [1, 2, 3, 8, 15, 16, 19, 22, 23, 24, 27, 28, 29, 30, 31, 32, 45, 48, 50, 51, 54, 55, 58, 59, 63, 64, 65, 67, 76, 77, 78, 79, 87, 89, 91, 92, 95, 140, 145, 146, 148, 150, 151, 152, 160, 164, 165, 166, 167, 168, 170, 171, 173, 174, 175, 176, 177, 178, 179, 181, 183, 184, 188, 190, 192, 193, 198, 202, 203, 204, 206, 207, 208, 209, 210, 211, 212, 213, 215, 216, 217]
    // Count:
    //  81
    //
    // COMMENTED OUT lines are NEVER USED IN LEGACY ENTRIES

    public static let rgs_v3_8: [LegacyMap] = [
        .init(
            1, 
            "Dividends Levi",
            "BEivKapProPok",
            "levi"
        ),
        .init(
            2, 
            "Dividends Casper",
            "BEivKapProPok",
            "casper"
        ),
        .init(
            3, 
            "Dividends Shusha",
            "BEivKapProPok",
            "shusha"
        ),
        // .init(
        //     4, 
        //     "Leash Rope",
        //     "WKprKvgKvg",
        //     "objects.storable.rope"
        // ),
        // .init(
        //     5, 
        //     "Leash Rings",
        //     "WKprKvgKvg",
        //     "NO SEPARATION BETWEEN O RINGS AND STOP RINGS?" // NOT YET SOLVED
        // ),
        // .init(
        //     6, 
        //     "Leash Tape",
        //     "WKprKvgKvg",
        //     ""
        // ),
        // .init(
        //     7, 
        //     "Other Raw Materials",
        //     "WKprKvgKvg",
        //     "" // NOT YET RESOLVED
        // ),

        .init(
            8, 
            "Direct Travel Cost",
            "WBedAutBra", // remap to travel cost
            "vehicle#honda_crv"
        ),
        
        // .init(
        //     9, 
        //     "Freight-in Cost",
        //     "", 
        //     "" 
        // ),

        // .init(
        //     10, 
        //     "Storage Cost",
        //     "",
        //     ""
        // ),

        // .init(
        //     11, 
        //     "Manufacturing Overhead",
        //     "acc",
        //     "ent"
        // ),

        // .init(
        //     12, 
        //     "Cash or Trade Discounts",
        //     "acc",
        //     "ent"
        // ),

        // .init(
        //     13, 
        //     "Purchase Returns and Allowances",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     14, 
        //     "Items for Resale",
        //     "acc",
        //     "ent"
        // ),

        .init(
            15, 
            "Advertising",
            "acc",
            "google_ads"
        ),

        .init(
            16, 
            "Marketing",
            "WBedKanDru",
            "business_cards"
        ),

        // .init(
        //     17, 
        //     "Sales Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     18, 
        //     "Other Costs of Sales",
        //     "acc",
        //     "ent"
        // ),

        .init(
            19, 
            "Indirect Travel Cost",
            "WBedAutBra",
            "vehicle#honda_crv"
        ),

        // .init(
        //     20, 
        //     "Rent",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     21, 
        //     "Utilities",
        //     "acc",
        //     "ent"
        // ),

        .init(
            22, 
            "Supplies",
            "WBedKanKan",
            "ent"
        ),


        //OVERRIDES ADDED
        .init(
            23, 
            "Insurance",
            "<MANUAL: INSURANCE GENERIC: Split into relevant ACCOUNT (car ins. cost (WBedAutAsa), or company legal (WBedAssBea)",
            "<MANUAL: INSURANCE GENERIC: Split into relevant entity (car, or legal)>"
        ),

        .init(
            24, 
            "Maintenance",
            "WBedAutRoa",
            "vehicle#honda_legend"
        ),

        // .init(
        //     25, 
        //     "Repairs",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     26, 
        //     "General Salaries",
        //     "acc",
        //     "ent"
        // ),


        .init(
            27, 
            "Bank Fees",
            "WBedAdlBan",
            "bunq"
        ),

        // RESOLVED IN OVERRIDES
        .init(
            28, 
            "Subscriptions",
            "MANUAL: IF SIMYO -> (WBedKanTef)IF SOFTWARE -> (WBedKanSof) IF HOSTING -> ()",
            "MANUAL: IF SIMYO -> (simyo)IF SOFTWARE -> (gopro, answerthepublic, openai) IF HOSTING -> (WBedVkkWeb)"
        ),

        // RESOLVED IN OVERRIDES
        .init(
            29, 
            "Vet Costs",
            "WBedAlkOal",
            "(vchn_middenmeer || van_duin_tot_dijk)"
        ),

        // RESOLVED IN OVERRIDES
        .init(
            30, 
            "Dog Care",
            "WBedAlkOal",
            "(vegavriend || pets_place)"
        ),

        // RESOLVED IN OVERRIDES
        .init(
            31, 
            "Other General Costs",
            "WBedAlkOal",
            "MANUAL: IF FOOD (CORRECTED LATER) -> (mcdonalds, h_earth) || IF GOOGLE -> (google) "
        ),

        .init(
            32, 
            "Consulting Fees",
            "WBedAeaAea",
            "sub_rosa"
        ),

        // .init(
        //     33, 
        //     "Administrative Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     34, 
        //     "Other Administrative Costs",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     35, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     36, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     37, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     38, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     39, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     40, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     41, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     42, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     43, 
        //     "Uncollectible Services Billed",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     44, 
        //     "Uncollectible Products Billed",
        //     "acc",
        //     "ent"
        // ),

        // OVERRIDES
        .init(
            45, 
            "Refunds to Overhead Expenses",
            "MANUAL: INSURANCE -> (WBedAutAsa), GOOGLE -> (WBedAlkOal), BUNQ -> (WBedAdlBan)",
            "MANUAL: REFUNDS: (vehicle#honda_crv), (google), (bunq)"
        ),

        // .init(
        //     46, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     47, 
        //     "Main Cash",
        //     "acc",
        //     "ent"
        // ),

        .init(
            48, 
            "Main",
            "BLimBanRba",
            "balance.main"
        ),

        // .init(
        //     49, 
        //     "Savings Main",
        //     "acc",
        //     "ent"
        // ),

        .init(
            50, 
            "Levi",
            "BLimBanRba",
            "balance.levi"
        ),

        .init(
            51, 
            "Savings Levi",
            "BLimBanSpa",
            "levi_savings"
        ),
        // .init(
        //     52, 
        //     "Travel Reimbursement Levi",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     53, 
        //     "VAT Reimbursement Levi",
        //     "acc",
        //     "ent"
        // ),
        .init(
            54, 
            "Shusha",
            "BLimBanRba",
            "balance.shusha"
        ),
        .init(
            55, 
            "Savings Shusha",
            "BLimBanSpa",
            "shusha_savings"
        ),
        // .init(
        //     56, 
        //     "Travel Reimbursement Shusha",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     57, 
        //     "VAT Reimbursement Shusha",
        //     "acc",
        //     "ent"
        // ),

        .init(
            58, 
            "Casper",
            "BLimBanRba",
            "balance.casper"
        ),
        .init(
            59, 
            "Savings Casper",
            "BLimBanSpa",
            "casper_savings"
        ),
        // .init(
        //     60, 
        //     "Travel Reimbursement Casper",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     61, 
        //     "VAT Reimbursement Casper",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     62, 
        //     "Call",
        //     "acc",
        //     "ent"
        // ),
        .init(
            63, 
            "Consult",
            "BVorDebHad",
            "consult"
        ),
        .init(
            64, 
            "Session",
            "BVorDebHad",
            "session"
        ),
        .init(
            65, 
            "Trajectory",
            "BVorDebHad",
            "any_trajectory"
        ),
        // .init(
        //     66, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        .init(
            67, 
            "Leash",
            "BVorDebHad",
            "leash"
        ),
        // .init(
        //     68, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     69, 
        //     "Call",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     70, 
        //     "Consult",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     71, 
        //     "Session",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     72, 
        //     "Trajectory",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     73, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     74, 
        //     "Leash",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     75, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        .init(
            76, 
            "Leashes",
            "BVrdGepVoo", // Voorraden > Gereed product
            "leash" // inferred from deliverable product
        ),
        .init(
            77, 
            "Leash Rope",
            "BVrdGehVoo", // Voorraden > Grond- en hulpstoffen
            "rope" // inferred from storable objects
        ),
        .init(
            78, 
            "Leash O-Rings",
            "BVrdGehVoo", // Voorraden > Grond- en hulpstoffen
            "o_ring"
        ),
        .init(
            79, 
            "Leash Tape",
            "BVrdGehVoo", // Voorraden > Grond- en hulpstoffen
            "tape"
        ),
        // .init(
        //     80, 
        //     "Rent",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     81, 
        //     "Utilities",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     82, 
        //     "Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     83, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     84, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     85, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     86, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        .init(
            87, 
            "Computers",
            "BMvaBeiVvpIna",
            "asset_placeholder"
        ),
        // .init(
        //     88, 
        //     "Computer Accesories",
        //     "acc",
        //     "ent"
        // ),

        .init(
            89, 
            "Monitors",
            "BMvaBeiVvpIna",
            "asset_placeholder"
        ),
        // .init(
        //     90, 
        //     "Furniture",
        //     "acc",
        //     "ent"
        // ),
        .init(
            91, 
            "Camera Equipment",
            "BMvaBeiVvpIna",
            "asset_placeholder"
        ),
        .init(
            92, 
            "Audio Equipment",
            "BMvaBeiVvpIna",
            "asset_placeholder"
        ),
        // .init(
        //     93, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     94, 
        //     "Other Equipment",
        //     "acc",
        //     "ent"
        // ),
        .init(
            95, 
            "Input VAT",
            "BVorVbkTvo",
            "belastingdienst"
        ),
        // .init(
        //     96, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     97, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     98, 
        //     "Editing Software",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     99, 
        //     "Authentication Software",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     100, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     101, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     102, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     103, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     104, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     105, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     106, 
        //     "Rent",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     107, 
        //     "Utilities",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     108, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     109, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     110, 
        //     "Direct Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     111, 
        //     "Social Security",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     112, 
        //     "Pensions",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     113, 
        //     "Other Personnel Cost",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     114, 
        //     "Direct Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     115, 
        //     "Social Security",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     116, 
        //     "Pensions",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     117, 
        //     "Other Personnel Cost",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     118, 
        //     "Direct Salaries",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     119, 
        //     "Social Security",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     120, 
        //     "Pensions",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     121, 
        //     "Other Personnel Cost",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     122, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     123, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     124, 
        //     "Call",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     125, 
        //     "Consult",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     126, 
        //     "Session",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     127, 
        //     "Trajectory",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     128, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     129, 
        //     "Leash",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     130, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     131, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     132, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     133, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     134, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     135, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     136, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     137, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     138, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     139, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),


        .init(
            140, 
            "Output VAT",
            "BSchBepBtwOla", // subaccount level5: hoog tarief!
            "belastingdienst"
        ),
        

        // .init(
        //     141, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     142, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     143, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     144, 
        //     "Other Obligations",
        //     "acc",
        //     "ent"
        // ),


        .init(
            145, 
            "Capital Contributions Levi",
            "BEivKapPrsPsk",
            "levi"
        ),

        .init(
            146, 
            "Capital Contributions Casper",
            "BEivKapPrsPsk",
            "casper"
        ),

        // .init(
        //     147, 
        //     "Capital Contributions Shusha",
        //     "acc",
        //     "ent"
        // ),

        .init(
            148, 
            "Retained Earnings",
            "BEivKapOndAow",
            "closure"
        ),

        // .init(
        //     149, 
        //     "Call Sales",
        //     "acc",
        //     "ent"
        // ),

        .init(
            150, 
            "Consult Sales",
            "WOmzNodOdh",
            "consult"
        ),
        .init(
            151, 
            "Session Sales",
            "WOmzNodOdh",
            "session"
        ),
        .init(
            152, 
            "Trajectory Sales",
            "WOmzNodOdh",
            "any_trajectory"
        ),
        // .init(
        //     153, 
        //     "Other Service Sales",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     154, 
        //     "Product Sales",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     155, 
        //     "Digital Sales",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     156, 
        //     "Other Sales",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     157, 
        //     "Other Income",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     158, 
        //     "General",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     159, 
        //     "Other",
        //     "acc",
        //     "ent"
        // ),

        .init(
            160, 
            "Income Summary",
            "BEivKapOndAow",
            "closure"
        ),

        // .init(
        //     161, 
        //     "Gain on Disposal of Assets",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     162, 
        //     "Loss on Disposal of Assets",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     163, 
        //     "Refunds to Cost of Revenue",
        //     "acc",
        //     "ent"
        // ),
        .init(
            164, 
            "VAT Rounding Remainder",
            "WFbeRlmRbb",
            "belastingdienst"
        ),
        .init(
            165, 
            "Leash Sales",
            "WOmzNopOlh",
            "leash"
        ),
        .init(
            166, 
            "Dog Care",
            "BVorDebHad", // vorderingen
            "boarding"
        ),
        .init(
            167, 
            "Dog Care Sales",
            "WOmzNodOdh", // omzet
            "boarding"
        ),
        .init(
            168, 
            "Interest Income",
            "WFbeRlmObr",
            "bunq"
        ),
        // .init(
        //     169, 
        //     "Resources",
        //     "acc",
        //     "ent"
        // ),
        .init(
            170, 
            "Software Expense",
            "WBedKanSof",
            "any_software"
        ),

        .init(
            171, 
            "Gear",
            "WBedEemKai",
            "any_camera_equipment"
        ),

        // .init(
        //     172, 
        //     "Data Storage Equipment",
        //     "acc",
        //     "ent"
        // ),

        .init(
            173, 
            "Leash Stop Rings",
            "BVrdGehVoo",
            "stop_ring"
        ),

        .init(
            174, 
            "Camera Equipment",
            "WBedEemKai", 
            "any_camera_equipment"
        ),

        .init(
            175, 
            "Data Storage Equipment",
            "WBedEemKai",
            "any_data_storage_hardware"
        ),

        .init(
            176, 
            "Hardware",
            "WBedKanKak", // (kantoor inventaris) wrong WBedEemKai -> WBedKanKak corrected
            "any_hardware"
        ),

        .init(
            177, 
            "Leashes",
            "WKprInpInp", // kostprijswaarde productiegoederen
            "leash"
        ),
        .init(
            178, 
            "Internal Use Leashes",
            "WKprVomVom",
            "leash"
        ),
        .init(
            179, 
            "Computers",
            "WAfsAmvBei",
            "asset_placeholder"
        ),
        // .init(
        //     180, 
        //     "Computer Accesories",
        //     "acc",
        //     "ent"
        // ),
        .init(
            181, 
            "Monitors",
            "WAfsAmvBei",
            "asset_placeholder"
        ),
        // .init(
        //     182, 
        //     "Furniture",
        //     "acc",
        //     "ent"
        // ),
        .init(
            183, 
            "Camera Equipment",
            "WAfsAmvBei",
            "asset_placeholder"
        ),
        .init(
            184, 
            "Audio Equipment",
            "WAfsAmvBei",
            "asset_placeholder"
        ),
        // .init(
        //     185, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     186, 
        //     "Other Equipment",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     187, 
        //     "Data Storage Equipment",
        //     "acc",
        //     "ent"
        // ),
        .init(
            188, 
            "Computers",
            "BMvaBeiCaeAfs", // Cumulatieve afschrijvingen . afschrijvingen
            "asset_placeholder"
        ),
        // .init(
        //     189, 
        //     "Computer Accesories",
        //     "acc",
        //     "ent"
        // ),
        .init(
            190, 
            "Monitors",
            "BMvaBeiCaeAfs",
            "asset_placeholder"
        ),
        // .init(
        //     191, 
        //     "Furniture",
        //     "acc",
        //     "ent"
        // ),
        .init(
            192, 
            "Camera Equipment",
            "BMvaBeiCaeAfs",
            "asset_placeholder"
        ),
        .init(
            193, 
            "Audio Equipment",
            "BMvaBeiCaeAfs",
            "asset_placeholder"
        ),
        // .init(
        //     194, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     195, 
        //     "Other Equipment",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     196, 
        //     "Data Storage Equipment",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     197, 
        //     "Rehabilitation",
        //     "acc",
        //     "ent"
        // ),

        .init(
            198, 
            "Adoption",
            "BVorDebHad", // vorderingen
            "adoption"
        ),
        // .init(
        //     199, 
        //     "Rehabilitation",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     200, 
        //     "Adoption",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     201, 
        //     "Rehabilitation Sales",
        //     "acc",
        //     "ent"
        // ),
        .init(
            202, 
            "Adoption Sales", 
            "WOmzNodOdh", // omzet
            "adoption"
        ),
        .init(
            203, 
            "Client Damage Claims",
            "WBedAssScb",
            "any_damage_claim"
        ),
        .init(
            204, 
            "PayPal",
            "BLimBanRba",
            "paypal"
        ),

        // .init(
        //     205, 
        //     "Stripe",
        //     "acc",
        //     "ent"
        // ),

        .init(
            206, 
            "Hosting Services",
            "WBedVkkWeb",
            "namecheap"
        ),
        .init(
            207, 
            "General",
            "WBedAlkOal",
            "google" // just a verification transaction in existing history, so no any_general needed
        ),

        .init(
            208, 
            "Research Material",
            "WBedKanVak",
            "any_literature"
        ),
        .init(
            209, 
            "Packaging",
            "WBedVkkVrk",
            "any_packagable"
        ),
        .init(
            210, 
            "Shipping",
            "WBedVkkVrk",
            "any_shippable"
        ),
        .init(
            211, 
            "Phones",
            "BMvaBeiVvpIna",
            "ent"
        ),
        .init(
            212, 
            "VAT Rounding Deficit",
            "WFbeOrlRlb",
            "belastingdienst"
        ),
        .init(
            213, 
            "Carry Forward Input VAT",
            "BVorVbkTvo",
            "carry_forward_vat"
        ),
        // .init(
        //     214, 
        //     "Carry Forward Output VAT",
        //     "acc",
        //     "ent"
        // ),
        .init(
            215, 
            "Work Clothes",
            "WBedOvpWkv",
            "any_clothing"
        ),

        .init(
            216, 
            "Phones",
            "BMvaBeiCaeAfs", // Cumulatieve afschrijvingen . afschrijvingen
            "asset_placeholder"
        ),
        .init(
            217, 
            "Phones",
            "WAfsAmvBei", // dep exp
            "asset_placeholder"
        ),
        // .init(
        //     218, 
        //     "Bijtelling IB",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     219, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     220, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     221, 
        //     "Vehicles",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     222, 
        //     "Levi Cash",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     223, 
        //     "Casper Cash",
        //     "acc",
        //     "ent"
        // ),
        // .init(
        //     224, 
        //     "Shusha Cash",
        //     "acc",
        //     "ent"
        // ),
    ]

    public static let rgs_v3_8_overrides: [LegacyMapOverrideExceptions] = [
        .init(
            legacyEntryIds: [
                63,
                64,
                90,
                100,
                108,
                114,
                135,
                156,
                215,
                330,
                388,
                501,
                579,
                669,
            ],
            legacyMapOverride: LegacyMap(
                30, 
                "Dog Care",
                "WBedAlkOal",
                "vegavriend"
            ),
        ),

        .init(
            legacyEntryIds: [
                558,
                595,
                604,
                608,
                622
            ],
            legacyMapOverride: LegacyMap(
                30, 
                "Dog Care",
                "WBedAlkOal",
                "pets_place"
            ),
        ),

        .init(
            legacyEntryIds: [
                639
            ],
            legacyMapOverride: LegacyMap(
                30, 
                "Dog Care",
                "WBedAlkOal",
                "pets_and_co"
            ),
        ),

        .init(
            legacyEntryIds: [
                149
            ],
            legacyMapOverride: .init(
                29, 
                "Vet Costs",
                "WBedAlkOal",
                "van_duin_tot_dijk"
            ),
        ),

        .init(
            legacyEntryIds: [
                688
            ],
            legacyMapOverride: .init(
                29, 
                "Vet Costs",
                "WBedAlkOal",
                "vchn_middenmeer"
            ),
        ),

        .init(
            legacyEntryIds: [
                150, 
                190,
                258
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "soepp"
            ),
        ),

        .init(
            legacyEntryIds: [
                197
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "indeed"
            ),
        ),

        .init(
            legacyEntryIds: [
                250
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "sencha"
            ),
        ),

        .init(
            legacyEntryIds: [
                257
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "luttik"
            ),
        ),

        .init(
            legacyEntryIds: [
                358,
                414,
                424,
                565,
                615,
                690
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "mcdonalds"
            ),
        ),

        .init(
            legacyEntryIds: [
                362,
                655
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "subway"
            ),
        ),

        .init(
            legacyEntryIds: [
                369
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "jumbo"
            ),
        ),

        .init(
            legacyEntryIds: [
                214
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "albert_heijn"
            ),
        ),

        .init(
            legacyEntryIds: [
                537
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "coffee_company"
            ),
        ),

        .init(
            legacyEntryIds: [
                538
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "vegan_bamboo_bar"
            ),
        ),

        .init(
            legacyEntryIds: [
                642
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "h_earth"
            ),
        ),

        .init(
            legacyEntryIds: [
                663
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "google"
            ),
        ),

        .init(
            legacyEntryIds: [
                735,
                736,
                737,
                738,
                739
            ],

            legacyMapOverride: .init(
                31, 
                "Other General Costs",
                "WBedAlkOal",
                "correction"
            ),
        ),

        .init(
            legacyEntryIds: [
                19
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedAdlBan",
                "bunq"
            ),
        ),

        .init(
            legacyEntryIds: [
                198
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedAlkOal",
                "indeed"
            ),
        ),

        .init(
            legacyEntryIds: [
                232,
                275,
                421,
                439,
                646,
                651,
                658
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedKanVak", // vakliteratuur
                "amazon"
            ),
        ),

        .init(
            legacyEntryIds: [
                242
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedKanDru", // drukwerk
                "vistaprint"
            ),
        ),

        .init(
            legacyEntryIds: [
                252,
                540
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedAlkOal", // general
                "amazon"
            ),
        ),

        .init(
            legacyEntryIds: [
                583
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedAssBea", // vergoeding verzekering premie -- premie kost
                "centraal_beheer"
            ),
        ),

        .init(
            legacyEntryIds: [
                662
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedOvpWkv", // kosten werkkleding
                "uniqlo"
            ),
        ),

        .init(
            legacyEntryIds: [
                663,
                229
            ],

            legacyMapOverride: .init(
                45, 
                "Refunds to Overhead Expenses",
                "WBedAlkOal", // general
                "google"
            ),
        ),

        .init(
            legacyEntryIds: [
                159,
                201,
                229,
                273,
                340,
                389,
                454,
                564,
                623,
            ],

            legacyMapOverride: .init(
                23, 
                "Insurance",
                "WBedAssBea",
                "centraal_beheer"
            ),
        ),

        .init(
            legacyEntryIds: [
                627,
                681,

            ],

            legacyMapOverride: .init(
                23, 
                "Insurance",
                "WBedAssBea",
                "unive"
            ),
        ),

        .init(
            legacyEntryIds: [
                307
            ],

            legacyMapOverride: .init(
                23, 
                "MISTAKENLY BOOKED AS INSURANCE",
                "WBedAdlBan",
                "bunq"
            ),
        ),


        .init(
            legacyEntryIds: [
                667
            ],

            legacyMapOverride: .init(
                28, 
                "Subscriptions",
                "WBedKanSof",
                "openai"
            ),
        ),

        .init(
            legacyEntryIds: [
                148,
                203,
                225,
                273,
                337,
                375,
                441,
                556,
                616,
                680,
            ],

            legacyMapOverride: .init(
                28, 
                "Phone cost",
                "WBedKanTef",
                "simyo"
            ),
        ),
        
        .init(
            legacyEntryIds: [
                557,
            ],

            legacyMapOverride: .init(
                28, 
                "Subscriptions",
                "WBedKanSof",
                "gopro"
            ),
        ),

        .init(
            legacyEntryIds: [
                613,
            ],

            legacyMapOverride: .init(
                28, 
                "Subscriptions",
                "WBedKanSof",
                "answerthepublic"
            ),
        ),

        .init(
            legacyEntryIds: [
                620,
            ],

            legacyMapOverride: .init(
                28, 
                "Web hosting (as subscriptions)",
                "WBedVkkWeb",
                "namecheap"
            ),
        ),
    ]

    // call before moving on with overrides
    public static func assertUniqueLegacyOverrides(_ overrides: [LegacyMapOverrideExceptions] = rgs_v3_8_overrides,
                                                   fatal: Bool = false) {
        do {
            _ = try overrides.validateUniqueOverrides()
        } catch let LegacyOverrideValidationError.duplicates(report) {
            let msg = "[LegacyOverrides] \(report.description)\n"
            // print to stderr as a WARNING by default
            FileHandle.standardError.write(Data(msg.utf8))
            if fatal { fatalError("Duplicate legacy overrides") }
        } catch {
            FileHandle.standardError.write(Data("[LegacyOverrides] \(error)\n".utf8))
            if fatal { fatalError("Legacy override validation error") }
        }
    }
}
