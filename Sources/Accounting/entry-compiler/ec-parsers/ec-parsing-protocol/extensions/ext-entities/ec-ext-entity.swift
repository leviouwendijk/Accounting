import Foundation

// Parsing helpers (segments already normalized: unit(x) → "#x")
public extension EntryCompilerParsing {
    /// Build an EntityRef from 1..3 flat segments (entries; alias-only allowed)
    @inline(__always)
    func makeEntityRef(from segs: [String]) throws -> EntityRef {
        switch segs.count {
        case 1:
            return .init(class: nil, family: nil, alias: EntityAlias.parse(segs[0]))
        case 2:
            return .init(class: segs[0], family: nil, alias: EntityAlias.parse(segs[1]))
        case 3:
            return .init(class: segs[0], family: segs[1], alias: EntityAlias.parse(segs[2]))
        default:
            throw ParserError.unexpectedToken(current, expected: "1..3 segments for entity path", at: loc())
        }
    }

    @inline(__always)
    func parseEntityRefFlexible() throws -> EntityRef {
        try makeEntityRef(from: readFlatSegments())
    }

    @inline(__always)
    func parseEntityRefInParens() throws -> EntityRef {
        let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
        return try makeEntityRef(from: segs)
    }
}

// entry: resolving refs against the built store
public extension EntryCompilerParsing {
    /// Parse an entity reference (flexible: 1..3 segments) and resolve it immediately.
    /// Use this in your `for … in …` parsing once the EntityStore is built.
    @inline(__always)
    func parseAndResolveEntityRefFlexible(using store: EntityStore) throws -> EntityDef {
        let ref = try parseEntityRefFlexible()
        return try store.resolve(ref, at: loc())
    }

    @inline(__always)
    func parseAndResolveEntityRefInParens(using store: EntityStore) throws -> EntityDef {
        let ref = try parseEntityRefInParens()
        return try store.resolve(ref, at: loc())
    }
}
