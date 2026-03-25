import Foundation

public struct LineSpec {
    let account: String?
    let entity: String?
    let dir: String?        // "dr" or "cr"
    let amount: Decimal?
    let invAdd: Decimal?
    let invRem: Decimal?
    
    public init(
        account: String?,
        entity: String?,
        dir: String?,        // "dr" or "cr",
        amount: Decimal?,
        invAdd: Decimal?,
        invRem: Decimal?
    ) {
        self.account = account
        self.entity = entity
        self.dir = dir
        self.amount = amount
        self.invAdd = invAdd
        self.invRem = invRem
    }
}


public extension LegacyJournalEntry {
    /// Minimal, isolated inventory block builder (as requested).
    /// Returns a formatted `inventory { … }` block or `nil` when neither add/remove is provided.
    func prepareInventoryBlock(add: Decimal?, remove: Decimal?) -> String? {
        if let q = add {
            return """
            inventory {
                mutation = add
                count = \(decString(q, scale: 0))
            }
            """
        }
        if let q = remove {
            return """
            inventory {
                mutation = remove
                count = \(decString(q, scale: 0))
            }
            """
        }
        return nil
    }

    // narrow helper for formatting decimals
    func decString(_ d: Decimal, scale: Int) -> String {
        var x = d, r = Decimal()
        NSDecimalRound(&r, &x, scale, .plain)
        return NSDecimalNumber(decimal: r).stringValue
    }

    // parse legacy inventory count strings (e.g. "5", "5,0", "  5 ") → Decimal
    func parseInventoryCount(_ s: String?) -> Decimal? {
        guard var t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
        if t.contains(",") { t = t.replacingOccurrences(of: ",", with: ".") }
        return Decimal(string: t, locale: Locale(identifier: "en_US_POSIX"))
    }

    func buildLineSpec() -> [LineSpec] {
        return [
            .init(account: nil, entity: nil,
                  dir: nil, amount: nil,
                  invAdd: parseInventoryCount(dr1InventoryIncrease), invRem: nil),
            .init(account: nil, entity: nil,
                  dir: nil, amount: nil,
                  invAdd: parseInventoryCount(dr2InventoryIncrease), invRem: nil),
            .init(account: nil, entity: nil,
                  dir: nil, amount: nil,
                  invAdd: nil, invRem: parseInventoryCount(cr1InventoryDecrease)),
            .init(account: nil, entity: nil,
                  dir: nil, amount: nil,
                  invAdd: nil, invRem: parseInventoryCount(cr2InventoryDecrease)),
        ]
    }
}
