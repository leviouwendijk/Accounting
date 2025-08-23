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

    public func resolve(_ ref: EntityRef) throws -> EntityDef {
        if let c = ref.`class`, let f = ref.family {
            let key = EntityKey(class: c, family: f, alias: ref.alias)

            if let d = byFull[key] {
                return d 
            }

            throw EntityStoreError.notFound(ref: ref.printable)
        }

        let cands = byAlias[ref.alias.name] ?? []
        if cands.isEmpty { 
            throw EntityStoreError.notFound(ref: ref.printable)
        }

        if let c = ref.`class`, let hit = cands.first(where: { $0.`class` == c }) {
            return byFull[hit]!
        }

        if cands.count == 1, let only = cands.first {
            return byFull[only]!
        }

        throw EntityStoreError.ambiguousAlias(
            alias: ref.alias.string,
            candidates: cands.map { $0.identifier(displaying: .fullchain) }
        )
    }
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
