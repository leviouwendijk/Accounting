import Foundation

public struct EntryCompilerLexingSets: Sendable, Codable {
    public let keywords: Set<String>
    public let idents: Set<String>
    
    public init(
        keywords: Set<String>,
        idents: Set<String>
    ) {
        self.keywords = keywords
        self.idents = idents
    }
}

public enum EntryCompilerLexingFlavor: Sendable {
    case settings
    case accounts
    case entities
    case entries
    case transactions
    case string
    case fallback
}

// public func entryCompilerIdentSet() -> Set<String> {
//     return [
//         "account",
//         "entity",
//     ]
// }

// public func entryCompilerStringBlockKeywordSet() -> Set<String> {
//     return [
//         "details",
//         "label",
//         "reason",
//         // "name"
//     ]
// }

public func entryCompilerLexingSets(flavor: EntryCompilerLexingFlavor) -> EntryCompilerLexingSets {
    let baseIdents: Set<String> = [
        "account",
        "entity"
    ]

    let global: Set<String> = [
        "id",
        "details",
        "date",
        "infer",
        "timezone",
        "true", "false",
        "reference"
    ]

    let shared: Set<String> = [
        "use",
        "code",
        "alias",
        "rollforward",
        "identifiers",
        "metadata",
        "amount",
        "currency",
        // "increase",
        // "decrease"
    ]

    let date: Set<String> = [
        "year",
        "month",
        "day"
    ]

    let entry: Set<String> = [
        "entry",
        "for", 
        "in",
        "debit", 
        "credit", 
        "dr", 
        "cr",
        "posting",
        "line",
        "transactions",
        "ref"
    ]

    let account: Set<String> = [
        // "account", // place as ident
        "label",
        "direction",
        "level",
        "applicability", "branche", "bv", "ez", "svc", "zzp",
        "rgs", "omslag"
    ]

    let entity: Set<String> = [
        // "entity", // place as ident
        "domain",
        "content",
        "variant", "subvariant",
    ]
    
    let ownership: Set<String> = [
        "ownership",
        "change",
        "effective_date",
        "percentage",
    ]

    let asset: Set<String> = [
        "asset",
        "depreciation",
        "valuation",
        "acquisition_cost",
        "direct",
        "indirect",

        "commission_date",
        "method",
        "useful_life", 
        "useful_life_months",
        "residual_value",
        "linked_entry",
        // "book_value"
        "capex"
    ]

    let transaction: Set<String> = [
        "transaction",
        "source",
        "gross",
        "name",
        "iban",
        "bic",
        "status",
        "platform_account_id",
        "platform_transaction_id",
        "counterparty"
    ]

    let inventory: Set<String> = [
        "inventory",

        "to",
        "from",

        "adding", "removing",
        "addition", "reduction",
        "add", "rm", "remove",
    ]

    let settings: Set<String> = [
        "settings", 
    ]

    let aggregation: Set<String> = [
        "aggregation", 
    ]

    let stringBlocks: Set<String> = [
        "details",
        "label",
        "reason",
        // "name"
    ]

    @inline(__always)
    func union(_ sets: Set<String>...) -> Set<String> {
        sets.reduce(into: Set<String>()) { $0.formUnion($1) }
    }

    // let kwSet: Set<String> = {
    //     var  s = Set<String>()
    //     [ 
    //         global, 
    //         date,
    //         entry,
    //         transaction,
    //         inventory,
    //         settings,
    //         aggregation 
    //     ].forEach { s.formUnion($0) }
    //     return s
    // }()

    // let kwSet = [
    //     global,
    //     shared,
    //     date,
    //     entry, 
    //     account,
    //     entity,
    //     ownership,
    //     asset,
    //     transaction, 
    //     inventory,
    //     settings,
    //     aggregation
    // ]
    // .reduce(into: Set<String>()) { $0.formUnion($1) }

    // return kwSet

    switch flavor {
    case .settings:
        let keywords = union(global, date, settings, aggregation)
        let idents   = baseIdents
        return .init(keywords: keywords, idents: idents)

    case .accounts:
        // promote “account” only here
        var keywords = union(global, shared, date, account, ownership, asset, aggregation)
        keywords.formUnion(["account"])
        // keep “entity” explicitly in idents (it will be ident by default, this just documents intent)
        let idents: Set<String> = ["entity"]
        return .init(keywords: keywords, idents: idents)

    case .entities:
        // promote “entity” only here
        var keywords = union(global, shared, date, entity, ownership, asset, aggregation)
        keywords.formUnion(["entity"])
        // keep “account” explicitly in idents
        let idents: Set<String> = ["account"]
        return .init(keywords: keywords, idents: idents)

    case .entries:
        // no “account” or “entity” as keywords here
        let keywords = union(global, shared, date, entry, inventory, aggregation)
        let idents: Set<String> = baseIdents
        return .init(keywords: keywords, idents: idents)

    case .transactions:
        let keywords = union(global, shared, date, transaction, aggregation)
        let idents: Set<String> = ["account", "entity"]
        return .init(keywords: keywords, idents: idents)

    case .string:
        return .init(keywords: stringBlocks, idents: [])

    case .fallback:
        let keywords = union(global, shared, date, entity, account, transaction, ownership, asset, aggregation)
        let idents: Set<String> = baseIdents
        return .init(keywords: keywords, idents: idents)
    }
}
