import Foundation

public struct EntityStore: Sendable, Codable {
    public let byFull: [EntityKey: EntityDef]
    public let byAlias: [String: [EntityKey]]

    public init(_ map: [EntityKey: EntityDef]) {
        self.byFull = map
        var idx: [String:[EntityKey]] = [:]
        for k in map.keys { idx[k.alias.name, default: []].append(k) }
        self.byAlias = idx
    }

    // public func resolve(_ ref: EntityRef, at loc: SourceLocation?) throws -> EntityDef {
    //     if let c = ref.`class`, let f = ref.family {
    //         let key = EntityKey(class: c, family: f, alias: ref.alias)
    //         if let d = byFull[key] { return d }
    //         throw EntityStoreError.notFound(ref: ref.printable, at: loc)
    //     }

    //     let cands = byAlias[ref.alias.name] ?? []
    //     guard !cands.isEmpty else {
    //         throw EntityStoreError.notFound(ref: ref.printable, at: loc)
    //     }
    //     if let c = ref.`class`, let hit = cands.first(where: { $0.`class` == c }) {
    //         return byFull[hit]!
    //     }
    //     if cands.count == 1, let only = cands.first {
    //         return byFull[only]!
    //     }
    //     throw EntityStoreError.ambiguousAlias(
    //         alias: ref.alias.string,
    //         candidates: cands.map { $0.identifier(displaying: .fullchain) },
    //         at: loc
    //     )
    // }

    public func resolve(_ ref: EntityRef, at loc: SourceLocation?) throws -> EntityDef {
        // Full key provided → direct lookup
        if let c = ref.`class`, let f = ref.family {
            let key = EntityKey(class: c, family: f, alias: ref.alias)
            if let d = byFull[key] { return d }
            throw EntityStoreError.notFound(ref: ref.printable, at: loc)
        }

        // Gather candidates by alias
        let cands = byAlias[ref.alias.name] ?? []
        guard !cands.isEmpty else {
            throw EntityStoreError.notFound(ref: ref.printable, at: loc)
        }

        // Start with all candidates, then narrow down
        var filtered = cands

        // If class is provided, prefer class filter first…
        if let c = ref.`class` {
            let byClass = cands.filter { $0.`class` == c }
            if byClass.count == 1 { return byFull[byClass[0]]! }
            if byClass.count > 1 {
                // Still ambiguous after class-filter
                throw EntityStoreError.ambiguousAlias(
                    alias: ref.alias.string,
                    candidates: byClass.map { $0.identifier(displaying: .fullchain) },
                    at: loc
                )
            }

            // …if no hits by class, try interpreting that same token as *family*.
            let byFamily = cands.filter { $0.family == c }
            if byFamily.count == 1 { return byFull[byFamily[0]]! }
            if byFamily.count > 1 {
                throw EntityStoreError.ambiguousAlias(
                    alias: ref.alias.string,
                    candidates: byFamily.map { $0.identifier(displaying: .fullchain) },
                    at: loc
                )
            }

            // neither class nor family matched → fall through to alias-only logic
            filtered = []
        }

        // If family is explicitly provided (3-seg form sometimes omits class), also filter.
        if let f = ref.family {
            let byF = (filtered.isEmpty ? cands : filtered).filter { $0.family == f }
            if byF.count == 1 { return byFull[byF[0]]! }
            if byF.count > 1 {
                throw EntityStoreError.ambiguousAlias(
                    alias: ref.alias.string,
                    candidates: byF.map { $0.identifier(displaying: .fullchain) },
                    at: loc
                )
            }
            filtered = byF
        }

        // Alias-only path
        if filtered.isEmpty {
            if cands.count == 1, let only = cands.first {
                return byFull[only]!
            }
            throw EntityStoreError.ambiguousAlias(
                alias: ref.alias.string,
                candidates: cands.map { $0.identifier(displaying: .fullchain) },
                at: loc
            )
        }

        // Exact single after previous filters
        if filtered.count == 1, let only = filtered.first {
            return byFull[only]!
        }

        // Still ambiguous
        throw EntityStoreError.ambiguousAlias(
            alias: ref.alias.string,
            candidates: filtered.map { $0.identifier(displaying: .fullchain) },
            at: loc
        )
    }


    var all: [EntityDef] { Array(byFull.values) }
    var count: Int { byFull.count }
}

public struct EntityStoreBuilder {
    private var map: [EntityKey: EntityDef] = [:]

    public mutating func add(_ def: EntityDef) throws {
        if map[def.key] != nil { 
            throw EntityStoreError.duplicateKey(def.key) 
        }
        map[def.key] = def
    }

    public func freeze() -> EntityStore { EntityStore(map) }
}

// public func loadEntityStore(at root: URL, lexer: (URL) throws -> [EntryCompilerToken]) throws -> EntityStore {
//     var b = EntityStoreBuilder()
//     // iterate config/entities/**/*.ec; parse each `entity { ... }` into EntityDef
//     // ...
//     return b.freeze()
// }
