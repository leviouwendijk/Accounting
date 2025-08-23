import Foundation

public extension EntityAlias {
    @inlinable
    func appendingVariant(_ v: String) -> EntityAlias {
        var vs = self.variant ?? []
        vs.append(v)
        return EntityAlias(name: self.name, variant: vs.isEmpty ? nil : vs)
    }
}

public extension EntryCompilerParsing {
    /// variant { use alias <v>; [metadata {…}] [details {…}] [subvariant { … }]* }
    @inlinable
    func parseVariantBlocks(baseKey: EntityKey) throws -> [EntityDef] {
        var defs: [EntityDef] = []
        while current == .keyword("variant") || current == .ident("variant") {
            advance(); try expect(.lBrace)
            var vName: String?
            var vMeta: [String:String] = [:]
            var vDetails: String?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"), .ident("use"):
                    advance(); try expect(.keyword("alias"))
                    let segs = (current == .lPar)
                        ? (try readSegmentsUntilRPar(allowAllAsAlias: true).1)
                        : readFlatSegments()
                    guard let only = segs.last, segs.count == 1 else {
                        throw ParserError.unexpectedToken(current, expected: "single alias", at: loc())
                    }
                    vName = only

                case .keyword("metadata"), .ident("metadata"):
                    vMeta = try parseStringMapBlock(named: "metadata")

                case .ident("details"), .keyword("details"):
                    vDetails = try parseFreeTextBlock(named: "details")

                case .keyword("subvariant"), .ident("subvariant"):
                    guard let v = vName else {
                        throw ParserError.unexpectedToken(current, expected: "variant alias before subvariant", at: loc())
                    }
                    let tmpKey = EntityKey(class: baseKey.class, family: baseKey.family, alias: baseKey.alias.appendingVariant(v))
                    defs.append(contentsOf: try parseSubvariantBlocks(parentKey: tmpKey))

                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details / subvariant", at: loc())
                }
            }
            try expect(.rBrace)

            if let v = vName {
                let vKey = EntityKey(class: baseKey.class, family: baseKey.family, alias: baseKey.alias.appendingVariant(v))
                defs.append(EntityDef(key: vKey, displayName: vDetails, metadata: vMeta, depreciation: nil))
            }
        }
        return defs
    }

    /// subvariant { use alias <sv>; [metadata {…}] [details {…}] }
    @inlinable
    func parseSubvariantBlocks(parentKey: EntityKey) throws -> [EntityDef] {
        var defs: [EntityDef] = []
        guard current == .keyword("subvariant") || current == .ident("subvariant") else { return defs }
        while current == .keyword("subvariant") || current == .ident("subvariant") {
            advance(); try expect(.lBrace)
            var name: String?
            var meta: [String:String] = [:]
            var details: String?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"), .ident("use"):
                    advance(); try expect(.keyword("alias"))
                    let segs = (current == .lPar)
                        ? (try readSegmentsUntilRPar(allowAllAsAlias: true).1)
                        : readFlatSegments()
                    guard let only = segs.last, segs.count == 1 else {
                        throw ParserError.unexpectedToken(current, expected: "single alias", at: loc())
                    }
                    name = only
                case .keyword("metadata"), .ident("metadata"):
                    meta = try parseStringMapBlock(named: "metadata")
                case .ident("details"), .keyword("details"):
                    details = try parseFreeTextBlock(named: "details")
                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details", at: loc())
                }
            }
            try expect(.rBrace)
            if let sv = name {
                let k = EntityKey(
                    class: parentKey.class, family: parentKey.family,
                    alias: parentKey.alias.appendingVariant(sv)
                )
                defs.append(EntityDef(key: k, displayName: details, metadata: meta, depreciation: nil))
            }
        }
        return defs
    }
}
