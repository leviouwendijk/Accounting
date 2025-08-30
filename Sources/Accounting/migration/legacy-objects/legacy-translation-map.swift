import Foundation

public struct LegacyMap: Sendable, Codable {
    public let legacyId: Int
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
        _ RGSAccountIdentifier: String,
        _ localEntity: String
    ) {
        self.legacyId = legacyId
        self.legacyName = legacyName
        self.account = RGSAccountIdentifier
        self.entity = localEntity
    }
}

public enum LegacyTranslation {
    public static let rgs_v3_8: [LegacyMap] = [
        .init(
            1, 
            "Dividends Levi",
            "BEivKapProPok",
            "people.owner.levi"
        ),
        .init(
            2, 
            "Dividends Casper",
            "BEivKapProPok",
            "people.owner.casper"
        ),
        .init(
            3, 
            "Dividends Shusha",
            "BEivKapProPok",
            "people.owner.shusha"
        ),
        .init(
            4, 
            "Leash Rope",
            "WKprKvgKvg",
            "objects.storable.rope"
        ),
        .init(
            5, 
            "Leash Rings",
            "WKprKvgKvg",
            "NO SEPARATION BETWEEN O RINGS AND STOP RINGS?" // NOT YET SOLVED
        ),
        .init(
            6, 
            "Leash Tape",
            "WKprKvgKvg",
            ""
        ),
        .init(
            7, 
            "Other Raw Materials",
            "WKprKvgKvg",
            "" // NOT YET RESOLVED
        ),
        .init(
            8, 
            "Direct Travel Cost",
            "WBedAutBra", // remap to travel cost
            "objects.usable.vehicle#honda_crv"
        ),
        
        // NEVER USED IN LEGACY ENTRIES
        .init(
            9, 
            "Freight-in Cost",
            "", 
            "" 
        ),

        // NEVER USED IN LEGACY ENTRIES
        .init(
            10, 
            "Storage Cost",
            "",
            ""
        ),

        // NEVER USED IN LEGACY ENTRIES
        .init(
            11, 
            "Manufacturing Overhead",
            "acc",
            "ent"
        ),

        // NEVER USED IN LEGACY ENTRIES
        .init(
            12, 
            "Cash or Trade Discounts",
            "acc",
            "ent"
        ),

        // NEVER USED IN LEGACY ENTRIES
        .init(
            13, 
            "Purchase Returns and Allowances",
            "acc",
            "ent"
        ),
        .init(
            14, 
            "Items for Resale",
            "acc",
            "ent"
        ),
        .init(
            15, 
            "Advertising",
            "acc",
            "ent"
        ),
        .init(
            16, 
            "Marketing",
            "acc",
            "ent"
        ),
        .init(
            17, 
            "Sales Salaries",
            "acc",
            "ent"
        ),
        .init(
            18, 
            "Other Costs of Sales",
            "acc",
            "ent"
        ),
        .init(
            19, 
            "Indirect Travel Cost",
            "acc",
            "ent"
        ),
        .init(
            20, 
            "Rent",
            "acc",
            "ent"
        ),
        .init(
            21, 
            "Utilities",
            "acc",
            "ent"
        ),
        .init(
            22, 
            "Supplies",
            "acc",
            "ent"
        ),
        .init(
            23, 
            "Insurance",
            "acc",
            "ent"
        ),
        .init(
            24, 
            "Maintenance",
            "acc",
            "ent"
        ),
        .init(
            25, 
            "Repairs",
            "acc",
            "ent"
        ),
        .init(
            26, 
            "General Salaries",
            "acc",
            "ent"
        ),
        .init(
            27, 
            "Bank Fees",
            "acc",
            "ent"
        ),
        .init(
            28, 
            "Subscriptions",
            "acc",
            "ent"
        ),
        .init(
            29, 
            "Vet Costs",
            "acc",
            "ent"
        ),
        .init(
            30, 
            "Dog Care",
            "acc",
            "ent"
        ),
        .init(
            31, 
            "Other General Costs",
            "acc",
            "ent"
        ),
        .init(
            32, 
            "Consulting Fees",
            "acc",
            "ent"
        ),
        .init(
            33, 
            "Administrative Salaries",
            "acc",
            "ent"
        ),
        .init(
            34, 
            "Other Administrative Costs",
            "acc",
            "ent"
        ),
        .init(
            35, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            36, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            37, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            38, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            39, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            40, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            41, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            42, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            43, 
            "Uncollectible Services Billed",
            "acc",
            "ent"
        ),
        .init(
            44, 
            "Uncollectible Products Billed",
            "acc",
            "ent"
        ),
        .init(
            45, 
            "Refunds to Overhead Expenses",
            "acc",
            "ent"
        ),
        .init(
            46, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            47, 
            "Main Cash",
            "acc",
            "ent"
        ),
        .init(
            48, 
            "Main",
            "acc",
            "ent"
        ),
        .init(
            49, 
            "Savings Main",
            "acc",
            "ent"
        ),
        .init(
            50, 
            "Levi",
            "acc",
            "ent"
        ),
        .init(
            51, 
            "Savings Levi",
            "acc",
            "ent"
        ),
        .init(
            52, 
            "Travel Reimbursement Levi",
            "acc",
            "ent"
        ),
        .init(
            53, 
            "VAT Reimbursement Levi",
            "acc",
            "ent"
        ),
        .init(
            54, 
            "Shusha",
            "acc",
            "ent"
        ),
        .init(
            55, 
            "Savings Shusha",
            "acc",
            "ent"
        ),
        .init(
            56, 
            "Travel Reimbursement Shusha",
            "acc",
            "ent"
        ),
        .init(
            57, 
            "VAT Reimbursement Shusha",
            "acc",
            "ent"
        ),
        .init(
            58, 
            "Casper",
            "acc",
            "ent"
        ),
        .init(
            59, 
            "Savings Casper",
            "acc",
            "ent"
        ),
        .init(
            60, 
            "Travel Reimbursement Casper",
            "acc",
            "ent"
        ),
        .init(
            61, 
            "VAT Reimbursement Casper",
            "acc",
            "ent"
        ),
        .init(
            62, 
            "Call",
            "acc",
            "ent"
        ),
        .init(
            63, 
            "Consult",
            "acc",
            "ent"
        ),
        .init(
            64, 
            "Session",
            "acc",
            "ent"
        ),
        .init(
            65, 
            "Trajectory",
            "acc",
            "ent"
        ),
        .init(
            66, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            67, 
            "Leash",
            "acc",
            "ent"
        ),
        .init(
            68, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            69, 
            "Call",
            "acc",
            "ent"
        ),
        .init(
            70, 
            "Consult",
            "acc",
            "ent"
        ),
        .init(
            71, 
            "Session",
            "acc",
            "ent"
        ),
        .init(
            72, 
            "Trajectory",
            "acc",
            "ent"
        ),
        .init(
            73, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            74, 
            "Leash",
            "acc",
            "ent"
        ),
        .init(
            75, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            76, 
            "Leashes",
            "acc",
            "ent"
        ),
        .init(
            77, 
            "Leash Rope",
            "acc",
            "ent"
        ),
        .init(
            78, 
            "Leash O-Rings",
            "acc",
            "ent"
        ),
        .init(
            79, 
            "Leash Tape",
            "acc",
            "ent"
        ),
        .init(
            80, 
            "Rent",
            "acc",
            "ent"
        ),
        .init(
            81, 
            "Utilities",
            "acc",
            "ent"
        ),
        .init(
            82, 
            "Salaries",
            "acc",
            "ent"
        ),
        .init(
            83, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            84, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            85, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            86, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            87, 
            "Computers",
            "acc",
            "ent"
        ),
        .init(
            88, 
            "Computer Accesories",
            "acc",
            "ent"
        ),
        .init(
            89, 
            "Monitors",
            "acc",
            "ent"
        ),
        .init(
            90, 
            "Furniture",
            "acc",
            "ent"
        ),
        .init(
            91, 
            "Camera Equipment",
            "acc",
            "ent"
        ),
        .init(
            92, 
            "Audio Equipment",
            "acc",
            "ent"
        ),
        .init(
            93, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            94, 
            "Other Equipment",
            "acc",
            "ent"
        ),
        .init(
            95, 
            "Input VAT",
            "acc",
            "ent"
        ),
        .init(
            96, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            97, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            98, 
            "Editing Software",
            "acc",
            "ent"
        ),
        .init(
            99, 
            "Authentication Software",
            "acc",
            "ent"
        ),
        .init(
            100, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            101, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            102, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            103, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            104, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            105, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            106, 
            "Rent",
            "acc",
            "ent"
        ),
        .init(
            107, 
            "Utilities",
            "acc",
            "ent"
        ),
        .init(
            108, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            109, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            110, 
            "Direct Salaries",
            "acc",
            "ent"
        ),
        .init(
            111, 
            "Social Security",
            "acc",
            "ent"
        ),
        .init(
            112, 
            "Pensions",
            "acc",
            "ent"
        ),
        .init(
            113, 
            "Other Personnel Cost",
            "acc",
            "ent"
        ),
        .init(
            114, 
            "Direct Salaries",
            "acc",
            "ent"
        ),
        .init(
            115, 
            "Social Security",
            "acc",
            "ent"
        ),
        .init(
            116, 
            "Pensions",
            "acc",
            "ent"
        ),
        .init(
            117, 
            "Other Personnel Cost",
            "acc",
            "ent"
        ),
        .init(
            118, 
            "Direct Salaries",
            "acc",
            "ent"
        ),
        .init(
            119, 
            "Social Security",
            "acc",
            "ent"
        ),
        .init(
            120, 
            "Pensions",
            "acc",
            "ent"
        ),
        .init(
            121, 
            "Other Personnel Cost",
            "acc",
            "ent"
        ),
        .init(
            122, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            123, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            124, 
            "Call",
            "acc",
            "ent"
        ),
        .init(
            125, 
            "Consult",
            "acc",
            "ent"
        ),
        .init(
            126, 
            "Session",
            "acc",
            "ent"
        ),
        .init(
            127, 
            "Trajectory",
            "acc",
            "ent"
        ),
        .init(
            128, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            129, 
            "Leash",
            "acc",
            "ent"
        ),
        .init(
            130, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            131, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            132, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            133, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            134, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            135, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            136, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            137, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            138, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            139, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            140, 
            "Output VAT",
            "acc",
            "ent"
        ),
        .init(
            141, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            142, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            143, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            144, 
            "Other Obligations",
            "acc",
            "ent"
        ),
        .init(
            145, 
            "Capital Contributions Levi",
            "acc",
            "ent"
        ),
        .init(
            146, 
            "Capital Contributions Casper",
            "acc",
            "ent"
        ),
        .init(
            147, 
            "Capital Contributions Shusha",
            "acc",
            "ent"
        ),
        .init(
            148, 
            "Retained Earnings",
            "acc",
            "ent"
        ),
        .init(
            149, 
            "Call Sales",
            "acc",
            "ent"
        ),
        .init(
            150, 
            "Consult Sales",
            "acc",
            "ent"
        ),
        .init(
            151, 
            "Session Sales",
            "acc",
            "ent"
        ),
        .init(
            152, 
            "Trajectory Sales",
            "acc",
            "ent"
        ),
        .init(
            153, 
            "Other Service Sales",
            "acc",
            "ent"
        ),
        .init(
            154, 
            "Product Sales",
            "acc",
            "ent"
        ),
        .init(
            155, 
            "Digital Sales",
            "acc",
            "ent"
        ),
        .init(
            156, 
            "Other Sales",
            "acc",
            "ent"
        ),
        .init(
            157, 
            "Other Income",
            "acc",
            "ent"
        ),
        .init(
            158, 
            "General",
            "acc",
            "ent"
        ),
        .init(
            159, 
            "Other",
            "acc",
            "ent"
        ),
        .init(
            160, 
            "Income Summary",
            "acc",
            "ent"
        ),
        .init(
            161, 
            "Gain on Disposal of Assets",
            "acc",
            "ent"
        ),
        .init(
            162, 
            "Loss on Disposal of Assets",
            "acc",
            "ent"
        ),
        .init(
            163, 
            "Refunds to Cost of Revenue",
            "acc",
            "ent"
        ),
        .init(
            164, 
            "VAT Rounding Remainder",
            "acc",
            "ent"
        ),
        .init(
            165, 
            "Leash Sales",
            "acc",
            "ent"
        ),
        .init(
            166, 
            "Dog Care",
            "acc",
            "ent"
        ),
        .init(
            167, 
            "Dog Care Sales",
            "acc",
            "ent"
        ),
        .init(
            168, 
            "Interest Income",
            "acc",
            "ent"
        ),
        .init(
            169, 
            "Resources",
            "acc",
            "ent"
        ),
        .init(
            170, 
            "Software Expense",
            "acc",
            "ent"
        ),
        .init(
            171, 
            "Gear",
            "acc",
            "ent"
        ),
        .init(
            172, 
            "Data Storage Equipment",
            "acc",
            "ent"
        ),
        .init(
            173, 
            "Leash Stop Rings",
            "acc",
            "ent"
        ),
        .init(
            174, 
            "Camera Equipment",
            "acc",
            "ent"
        ),
        .init(
            175, 
            "Data Storage Equipment",
            "acc",
            "ent"
        ),
        .init(
            176, 
            "Hardware",
            "acc",
            "ent"
        ),
        .init(
            177, 
            "Leashes",
            "acc",
            "ent"
        ),
        .init(
            178, 
            "Internal Use Leashes",
            "acc",
            "ent"
        ),
        .init(
            179, 
            "Computers",
            "acc",
            "ent"
        ),
        .init(
            180, 
            "Computer Accesories",
            "acc",
            "ent"
        ),
        .init(
            181, 
            "Monitors",
            "acc",
            "ent"
        ),
        .init(
            182, 
            "Furniture",
            "acc",
            "ent"
        ),
        .init(
            183, 
            "Camera Equipment",
            "acc",
            "ent"
        ),
        .init(
            184, 
            "Audio Equipment",
            "acc",
            "ent"
        ),
        .init(
            185, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            186, 
            "Other Equipment",
            "acc",
            "ent"
        ),
        .init(
            187, 
            "Data Storage Equipment",
            "acc",
            "ent"
        ),
        .init(
            188, 
            "Computers",
            "acc",
            "ent"
        ),
        .init(
            189, 
            "Computer Accesories",
            "acc",
            "ent"
        ),
        .init(
            190, 
            "Monitors",
            "acc",
            "ent"
        ),
        .init(
            191, 
            "Furniture",
            "acc",
            "ent"
        ),
        .init(
            192, 
            "Camera Equipment",
            "acc",
            "ent"
        ),
        .init(
            193, 
            "Audio Equipment",
            "acc",
            "ent"
        ),
        .init(
            194, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            195, 
            "Other Equipment",
            "acc",
            "ent"
        ),
        .init(
            196, 
            "Data Storage Equipment",
            "acc",
            "ent"
        ),
        .init(
            197, 
            "Rehabilitation",
            "acc",
            "ent"
        ),
        .init(
            198, 
            "Adoption",
            "acc",
            "ent"
        ),
        .init(
            199, 
            "Rehabilitation",
            "acc",
            "ent"
        ),
        .init(
            200, 
            "Adoption",
            "acc",
            "ent"
        ),
        .init(
            201, 
            "Rehabilitation Sales",
            "acc",
            "ent"
        ),
        .init(
            202, 
            "Adoption Sales",
            "acc",
            "ent"
        ),
        .init(
            203, 
            "Client Damage Claims",
            "acc",
            "ent"
        ),
        .init(
            204, 
            "PayPal",
            "acc",
            "ent"
        ),
        .init(
            205, 
            "Stripe",
            "acc",
            "ent"
        ),
        .init(
            206, 
            "Hosting Services",
            "acc",
            "ent"
        ),
        .init(
            207, 
            "General",
            "acc",
            "ent"
        ),
        .init(
            208, 
            "Research Material",
            "acc",
            "ent"
        ),
        .init(
            209, 
            "Packaging",
            "acc",
            "ent"
        ),
        .init(
            210, 
            "Shipping",
            "acc",
            "ent"
        ),
        .init(
            211, 
            "Phones",
            "acc",
            "ent"
        ),
        .init(
            212, 
            "VAT Rounding Deficit",
            "acc",
            "ent"
        ),
        .init(
            213, 
            "Carry Forward Input VAT",
            "acc",
            "ent"
        ),
        .init(
            214, 
            "Carry Forward Output VAT",
            "acc",
            "ent"
        ),
        .init(
            215, 
            "Work Clothes",
            "acc",
            "ent"
        ),
        .init(
            216, 
            "Phones",
            "acc",
            "ent"
        ),
        .init(
            217, 
            "Phones",
            "acc",
            "ent"
        ),
        .init(
            218, 
            "Bijtelling IB",
            "acc",
            "ent"
        ),
        .init(
            219, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            220, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            221, 
            "Vehicles",
            "acc",
            "ent"
        ),
        .init(
            222, 
            "Levi Cash",
            "acc",
            "ent"
        ),
        .init(
            223, 
            "Casper Cash",
            "acc",
            "ent"
        ),
        .init(
            224, 
            "Shusha Cash",
            "acc",
            "ent"
        ),
    ]
}
