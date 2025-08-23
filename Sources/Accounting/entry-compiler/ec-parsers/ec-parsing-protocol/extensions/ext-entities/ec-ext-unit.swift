import Foundation

public extension EntryCompilerParsing {
    // allow: unit { use alias levi_air_m2 }  OR  unit levi_air_m2 { … }
    @inlinable
    func parseUnitBlocks(
        baseKey: EntityKey,
        defaultTZ: TimeZone
    ) throws -> [EntityDef] {
        var out: [EntityDef] = []

        while current == .keyword("unit") || current == .ident("unit") {
            advance()

            var alias: EntityAlias? = nil
            if current != .lBrace {
                alias = EntityAlias.parse(try readSingleAliasFlexible())
            }

            try expect(.lBrace)
            var displayName: String?
            var metadata: [String:String] = [:]
            var details: String?
            var dep: DepreciationConfig?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"):
                    guard alias == nil else {
                        throw ParserError.unexpectedToken(current, expected: "metadata/details/depreciation", at: loc())
                    }
                    advance(); try expect(.keyword("alias"))
                    alias = EntityAlias.parse(try readSingleAliasFlexible())

                case .ident("display_name"):
                    advance(); try expect(.equals)
                    guard case let .string(s) = current else {
                        throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                    }
                    displayName = s; advance()

                case .ident("metadata"), .keyword("metadata"):
                    metadata = try parseStringMapBlock(named: "metadata")

                case .ident("details"), .keyword("details"):
                    details = try parseFreeTextBlock(named: "details")

                case .ident("depreciation"), .keyword("depreciation"):
                    dep = try parseDepreciationBlock(meta: &metadata, tz: defaultTZ)

                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details / depreciation", at: loc())
                }
            }
            try expect(.rBrace)

            guard let a = alias else {
                throw ParserError.unexpectedToken(current, expected: "unit { use alias … } or unit <alias> { … }", at: loc())
            }
            let unitKey = EntityKey(class: baseKey.class, family: baseKey.family, alias: a)
            var mergedMeta = metadata
            if let d = details { mergedMeta["details"] = d }
            out.append(EntityDef(key: unitKey, displayName: displayName, metadata: mergedMeta, depreciation: dep))
        }

        return out
    }

    // type <ident> — store as metadata["type"]
    @inlinable
    func parseTypeDirective(into meta: inout [String:String]) -> Bool {
        guard current == .ident("type") else { return false }
        advance()
        switch current {
        case let .ident(s):
            meta["type"] = s; advance(); return true
        case let .keyword(k):
            meta["type"] = k; advance(); return true
        default:
            return false
        }
    }
}
