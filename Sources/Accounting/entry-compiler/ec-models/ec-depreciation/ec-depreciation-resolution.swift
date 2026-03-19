import Foundation

public enum DepreciationResolutionError: LocalizedError {
    case bothDraftAndFinal(EntityKey)
    case missingAccountRef(EntityKey)

    public var errorDescription: String? {
        switch self {
        case .bothDraftAndFinal(let k):
            return "Entity \(k.identifier(displaying: .fullchain)) has both a resolved depreciation config and a draft. Remove one."
        case .missingAccountRef(let k):
            return "Entity \(k.identifier(displaying: .fullchain)) depreciation block is missing `account`."
        }
    }
}

public enum DepreciationResolutionPass {
    public static func run(
        on entities: EntityStore,
        using accounts: AccountStore
    ) throws -> EntityStore {
        var newMap: [EntityKey: EntityDef] = entities.byFull   // copy, because EntityStore is immutable. :contentReference[oaicite:3]{index=3}

        for (key, var def) in newMap {
            let hasFinal = (def.depreciation != nil)
            let hasDraft = (def.depreciationDraft != nil)

            if hasFinal && hasDraft {
                throw DepreciationResolutionError.bothDraftAndFinal(key)
            }

            if let draft = def.depreciationDraft {
                // Resolve account ref → AccountKey via node-backed store
                let cfg = try draft.resolve(using: entities, accounts: accounts, at: nil)
                try cfg.validate() // your strong safety checks (life > 0, residual ≤ cost, etc.) :contentReference[oaicite:4]{index=4}

                def.depreciation = cfg
                def.depreciationDraft = nil
                newMap[key] = def
            } else if let cfg = def.depreciation {
                // Validate existing final config as well
                try cfg.validate()                                // :contentReference[oaicite:5]{index=5}
                newMap[key] = def
            } else {
                // no depreciation on this entity → nothing to do
            }
        }

        return EntityStore(newMap)
    }
}
