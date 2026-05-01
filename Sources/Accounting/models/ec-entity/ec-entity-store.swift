import Foundation
import Position

public struct EntityStore: Sendable, Codable {
    public let byFull: [EntityKey: EntityDef]
    public let byAlias: [String: [EntityKey]]

    public init(_ map: [EntityKey: EntityDef]) {
        self.byFull = map
        var idx: [String:[EntityKey]] = [:]
        for k in map.keys { idx[k.alias.name, default: []].append(k) }
        self.byAlias = idx
    }

    public func resolve(_ ref: EntityRef, at loc: Position?) throws -> EntityDef {
        // 1) Full key → direct lookup
        if let c = ref.`class`, let f = ref.family {
            let key = EntityKey(class: c, family: f, alias: ref.alias)
            if let d = byFull[key] { return d }
            throw EntityStoreError.notFound(ref: ref.printable, at: loc)
        }

        // // 2) Candidates by alias
        // let all = byAlias[ref.alias.name] ?? []
        // guard !all.isEmpty else {
        //     throw EntityStoreError.notFound(ref: ref.printable, at: loc)
        // }

        // 2) Candidates by alias
        var all = byAlias[ref.alias.name] ?? []

        // 2b) NEW: ending-alias (suffix) fallback when alias bucket is empty.
        // e.g. ref.alias.name == "bulldog" should match "...#bulldog"
        if all.isEmpty {
            let needle = ref.alias.name.lowercased()
            var suffixMatches: [EntityKey] = []
            suffixMatches.reserveCapacity(16)

            // scan existing keys once
            var seen = Set<EntityKey>()
            for (key, _) in byFull where !seen.contains(key) {
                seen.insert(key)
                let parts = key.alias.string.lowercased().split(separator: "#")
                if let last = parts.last, last == needle {
                    suffixMatches.append(key)
                }
            }

            if !suffixMatches.isEmpty {
                all = suffixMatches
            }
        }

        guard !all.isEmpty else {
            throw EntityStoreError.notFound(ref: ref.printable, at: loc)
        }

        // Narrow by class/family (NO early ambiguous throws; we want root/#any prefs to apply)
        var base = all

        if let c = ref.`class` {
            let byClass = base.filter { $0.`class` == c }
            if byClass.count == 1 { return byFull[byClass[0]]! }
            if !byClass.isEmpty { base = byClass }
            else {
                // Treat provided class token as family if class had no hits
                let byFamily = base.filter { $0.family == c }
                if byFamily.count == 1 { return byFull[byFamily[0]]! }
                if !byFamily.isEmpty { base = byFamily }
            }
        }

        if let f = ref.family {
            let byF = base.filter { $0.family == f }
            if byF.count == 1 { return byFull[byF[0]]! }
            if !byF.isEmpty { base = byF }
        }

        // Helpers
        func def(_ k: EntityKey) -> EntityDef { byFull[k]! }
        func fullID(_ k: EntityKey) -> String { k.identifier(displaying: .fullchain) }
        @inline(__always) func variants(of a: EntityAlias) -> [String] { a.variant ?? [] }
        @inline(__always) func lower(_ xs: [String]) -> [String] { xs.map { $0.lowercased() } }
        func ambiguous(_ cands: [EntityKey]) -> Error {
            EntityStoreError.ambiguousAlias(
                alias: ref.alias.string,
                candidates: cands.map(fullID),
                at: loc
            )
        }

        let refVars = lower(variants(of: ref.alias))
        let hasAny = refVars.contains("any")

        // 3) Explicit variants (not wildcard)
        if !refVars.isEmpty && !hasAny {
            let exact = base.filter { lower(variants(of: $0.alias)) == refVars }
            if exact.count == 1 { return def(exact[0]) }
            if exact.count > 1 { throw ambiguous(exact) }
            // else fall through: maybe class/family narrowing already unique
        }

        // 4) '#any' wildcard semantics
        if hasAny {
            // 4a. Prefer explicit '#any' entity if present uniquely
            let exactAny = base.filter { lower(variants(of: $0.alias)) == refVars }
            if exactAny.count == 1 { return def(exactAny[0]) }

            // 4b. Prefer unique root (no variants)
            let roots = base.filter { variants(of: $0.alias).isEmpty }
            if roots.count == 1 { return def(roots[0]) }

            // 4c. Deterministic fallback: nearest to root (fewest variants), tie-break by full id
            if let chosen = base.min(by: { lhs, rhs in
                let lv = variants(of: lhs.alias).count
                let rv = variants(of: rhs.alias).count
                if lv != rv { return lv < rv }
                return fullID(lhs) < fullID(rhs)
            }) {
                return def(chosen)
            }
        }

        // 5) No variants supplied → prefer unique root if available
        if refVars.isEmpty {
            let roots = base.filter { variants(of: $0.alias).isEmpty }
            if roots.count == 1 { return def(roots[0]) }
        }

        // 6) If narrowing made it unique, return it
        if base.count == 1 { return def(base[0]) }

        // 7) Still ambiguous
        throw ambiguous(base)
    }

    var all: [EntityDef] { Array(byFull.values) }
    var count: Int { byFull.count }
}

public struct EntityStoreBuilder {
    public init() {}

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

public extension EntityStore {
    var idIndex: [EntityKey: Int] {
        var out: [EntityKey: Int] = [:]
        var next = 1
        for k in byFull.keys.sorted(by: {
            $0.identifier(displaying: .fullchain) < $1.identifier(displaying: .fullchain)
        }) {
            out[k] = next
            next += 1
        }
        return out
    }

    /// Build normalized OwnershipSlice[] *as of* a date from OwnerEquity on each EntityDef.
    /// Accepts percentages in 0…1 or 0…100; normalizes to sum==1.
    func ownershipSlices(asOf date: Date) -> [OwnershipSlice] {
        var raw: [(id: Int, pct: Decimal)] = []

        let idx = idIndex
        for def in byFull.values {
            guard let oe = def.ownerEquity, let id = idx[def.key] else { continue }
            var p = oe.percentage(on: date)         // Decimal
            if p > 1 { p /= 100 }                   // allow “50.0” as 50%
            if p > 0 { raw.append((id, p)) }
        }

        let total = raw.reduce(Decimal(0)) { $0 + $1.pct }
        guard total > 0 else { return [] }

        return raw.map { OwnershipSlice(entityId: $0.id, percent: $0.pct / total) }
    }
}
