import Foundation

public func entryCompilerKeywordSet() -> Set<String> {
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
        "account",
        "label",
        "direction",
        "level",
        "applicability", "branche", "bv", "ez", "svc", "zzp",
        "rgs", "omslag"
    ]

    let entity: Set<String> = [
        "entity",
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

    let kwSet = [
        global,
        shared,
        date,
        entry, 
        account,
        entity,
        ownership,
        asset,
        transaction, 
        inventory,
        settings,
        aggregation
    ]
    .reduce(into: Set<String>()) { $0.formUnion($1) }

    return kwSet
}
