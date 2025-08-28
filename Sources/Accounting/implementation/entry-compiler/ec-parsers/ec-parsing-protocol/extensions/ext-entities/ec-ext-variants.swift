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
    // allow: variant { use alias 20x4mm }  OR  variant 20x4mm { … }
    @inlinable
    func parseVariantBlocks(baseKey: EntityKey) throws -> [EntityDef] {
        var defs: [EntityDef] = []
        while current == .keyword("variant") || current == .ident("variant") {
            advance()

            // optional inline alias
            var vName: String? = nil
            if current != .lBrace {
                vName = try readSingleAliasFlexible()
            }

            try expect(.lBrace)
            var vMeta: [String:String] = [:]
            var vDetails: String?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"):
                    guard vName == nil else {
                        throw ParserError.unexpectedToken(current, expected: "metadata/details/subvariant", at: loc())
                    }
                    advance(); try expect(.keyword("alias"))
                    vName = try readSingleAliasFlexible()

                case .keyword("metadata"):
                    vMeta = try parseStringMapBlock(named: "metadata")

                case .ident("details"):
                    vDetails = try parseFreeTextBlock(named: "details")

                case .keyword("subvariant"), .keyword("subvariant"):
                    guard let v = vName else {
                        throw ParserError.unexpectedToken(current, expected: "variant alias before subvariant", at: loc())
                    }
                    let parent = EntityKey(class: baseKey.class, family: baseKey.family,
                                           alias: baseKey.alias.appendingVariant(v))
                    defs.append(contentsOf: try parseSubvariantBlocks(parentKey: parent))

                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details / subvariant", at: loc())
                }
            }
            try expect(.rBrace)

            if let v = vName {
                let k = EntityKey(class: baseKey.class, family: baseKey.family,
                                  alias: baseKey.alias.appendingVariant(v))
                defs.append(EntityDef(key: k, displayName: vDetails, metadata: vMeta, depreciation: nil))
            }
        }
        return defs
    }

    // Allow: subvariant { use alias stainless_steel }  OR  subvariant stainless_steel { … }
    @inlinable
    func parseSubvariantBlocks(parentKey: EntityKey) throws -> [EntityDef] {
        var defs: [EntityDef] = []
        while current == .keyword("subvariant") {
            advance()

            var name: String? = nil
            if current != .lBrace {
                name = try readSingleAliasFlexible()
            }

            try expect(.lBrace)
            var meta: [String:String] = [:]
            var details: String?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"):
                    guard name == nil else {
                        throw ParserError.unexpectedToken(current, expected: "metadata/details", at: loc())
                    }
                    advance(); try expect(.keyword("alias"))
                    name = try readSingleAliasFlexible()

                case .keyword("metadata"):
                    meta = try parseStringMapBlock(named: "metadata")

                case .ident("details"):
                    details = try parseFreeTextBlock(named: "details")

                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details", at: loc())
                }
            }
            try expect(.rBrace)

            if let sv = name {
                let k = EntityKey(class: parentKey.class, family: parentKey.family,
                                  alias: parentKey.alias.appendingVariant(sv))
                defs.append(EntityDef(key: k, displayName: details, metadata: meta, depreciation: nil))
            }
        }
        return defs
    }
}
