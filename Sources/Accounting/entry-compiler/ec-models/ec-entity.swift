import Foundation

public struct EntityDef: Sendable, Codable {
    public let key: EntityKey
    public var displayName: String?
    public var metadata: [String:String]
    public var depreciation: DepreciationConfig?
    
    public init(
        key: EntityKey,
        displayName: String?,
        metadata: [String:String],
        depreciation: DepreciationConfig?
    ) {
        self.key = key
        self.displayName = displayName
        self.metadata = metadata
        self.depreciation = depreciation
    }
}

public enum DepreciationMethod: String, Codable, Sendable { 
    case straight_line, sl
    case double_declining_balance, ddb
    case sum_of_year_digits, syd
    case units_of_production, uop
}

public struct DepreciationConfig: Sendable, Codable {
    public var method: DepreciationMethod?
    public var usefulLifeYears: Decimal?
    public var residualValuePercent: Decimal
    public var residualValueAmount: Decimal?
    public var effectiveDate: Date?
    
    public init(
        method: DepreciationMethod?,
        usefulLifeYears: Decimal?,
        residualValuePercent: Decimal,   
        residualValueAmount: Decimal?,
        effectiveDate: Date?
    ) {
        self.method = method
        self.usefulLifeYears = usefulLifeYears
        self.residualValuePercent = residualValuePercent
        self.residualValueAmount = residualValueAmount
        self.effectiveDate = effectiveDate
    }
}

/// Possibly-partial reference from entries: 1..3 segments allowed
public struct EntityRef: Hashable, Codable, Sendable {
    public let `class`: String?
    public let family: String?
    public let alias: EntityAlias

    public init(class: String?, family: String?, alias: EntityAlias) {
        self.`class` = `class`; self.family = family; self.alias = alias
    }

    public var printable: String {
        [`class`, family, alias.string].compactMap { $0 }.joined(separator: ".")
    }
}

// ===============================================
// Entity Store (immutable, Sendable) + Builder
// ===============================================
public struct EntityStore: Sendable, Codable {
    public let byFull: [EntityKey: EntityDef]        // full key → def
    public let byAlias: [String: [EntityKey]]        // alias.name → candidates

    public init(_ map: [EntityKey: EntityDef]) {
        self.byFull = map
        var idx: [String:[EntityKey]] = [:]
        for k in map.keys { idx[k.alias.name, default: []].append(k) }
        self.byAlias = idx
    }

    /// Entries may pass alias-only or partially qualified refs.
    public func resolve(_ ref: EntityRef) throws -> EntityDef {
        // Fast path: fully qualified
        if let c = ref.`class`, let f = ref.family {
            let key = EntityKey(class: c, family: f, alias: ref.alias)
            if let d = byFull[key] { return d }
            throw ParserError.entityNotFoundRef(EntityRef(class: c, family: f, alias: ref.alias).printable)
        }
        // Alias-only or class+alias
        let cands = byAlias[ref.alias.name] ?? []
        if cands.isEmpty { throw ParserError.entityNotFoundRef(ref.printable) }
        if let c = ref.`class` {
            if let hit = cands.first(where: { $0.`class` == c }) { return byFull[hit]! }
        }
        if cands.count == 1, let only = cands.first { return byFull[only]! }
        throw ParserError.ambiguousEntityAlias(alias: ref.alias.string, candidates: cands.map { $0.identifier(displaying: .fullchain) })
    }
}

public struct EntityStoreBuilder {
    private var map: [EntityKey: EntityDef] = [:]

    public mutating func add(_ def: EntityDef) throws {
        if map[def.key] != nil { throw ParserError.duplicateEntityKey(def.key) }
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
