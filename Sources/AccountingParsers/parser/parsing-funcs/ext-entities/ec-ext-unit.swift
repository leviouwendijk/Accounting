import Foundation
import Accounting

public extension EntryCompilerParsing {
    // TESTING EXPANDED ALLOWANCE OF UNIT OF
    // allow: 
    //   unit { use alias air_m2 } 
    //   unit air_m2 { … } 
    //   unit of levi air_m2 { … } 
    //   unit of levi { use alias air_m2 … } 
    @inlinable
    func parseUnitBlocks(
        baseKey: EntityKey,
        defaultTZ: TimeZone
    ) throws -> [EntityDef] {
        var out: [EntityDef] = []

        while current == .keyword("unit") || current == .ident("unit") {
            advance()

            // NEW: optional inline `of <owner>` before the block (and before/after inline alias)
            var owner: String? = nil
            var alias: EntityAlias? = nil

            if current != .lBrace {
                if current == .ident("of") || current == .keyword("of") {
                    advance()
                    owner = try readSingleAliasFlexible()
                    // allow optional inline alias after owner
                    if current != .lBrace {
                        alias = try EntityAlias.parse(try readSingleAliasFlexible())
                    }
                } else {
                    // old style: unit <alias> { … }
                    alias = try EntityAlias.parse(try readSingleAliasFlexible())
                }
            }

            try expect(.lBrace)
            var displayName: String?
            var metadata: [String:String] = [:]
            var profile: EntityUnitProfile?
            var details: String?
            var dep: DepreciationConfigDraft?
            var kiaDraft: KIADraft?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"):
                    guard alias == nil else {
                        throw ParserError.unexpectedToken(current, expected: "metadata/details/depreciation/of", at: loc())
                    }
                    advance(); try expect(.keyword("alias"))
                    alias = try EntityAlias.parse(try readSingleAliasFlexible())

                // NEW: block-form owner
                case .ident("of"), .keyword("of"):
                    advance()
                    owner = try readSingleAliasFlexible()

                case .ident("display"), .keyword("display"):
                    displayName = try parseFreeTextBlock(named: "display")

                // case .ident("display_name"):
                //     advance(); try expect(.equals)
                //     guard case let .string(s) = current else {
                //         throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                //     }
                //     displayName = s; advance()

                case .ident("metadata"), .keyword("metadata"):
                    metadata = try parseStringMapBlock(named: "metadata")

                case .ident("profile"), .keyword("profile"):
                    advance()
                    profile = try parseEntityUnitProfileBlock(tz: defaultTZ)
                    core.trace("  profile { … }")

                case .ident("details"), .keyword("details"):
                    details = try parseFreeTextBlock(named: "details")

                case .ident("depreciation"), .keyword("depreciation"):
                    dep = try parseDepreciationBlock(meta: &metadata, tz: defaultTZ)

                case .ident("kia"), .keyword("kia"):
                    advance()
                    kiaDraft = try parseKIABlock()

                default:
                    throw ParserError.unexpectedToken(
                        current, 
                        expected: "use alias / of / metadata / profile / details / depreciation", 
                        at: loc()
                    )
                }
            }
            try expect(.rBrace)

            guard let a = alias else {
                throw ParserError.unexpectedToken(current, expected: "unit { use alias … } or unit <alias> { … }", at: loc())
            }

            // Compose final alias:
            // - If owner is present: base#owner#(unit alias and its variants)
            // - If no owner: preserve old behavior (just the unit alias – back-compat)
            func merged(_ base: EntityAlias, with child: EntityAlias) throws -> EntityAlias {
                var out = try base.appendingVariant(child.name)
                if let variants = child.variant {
                    for variant in variants {
                        out = try out.appendingVariant(variant)
                    }
                }
                return out
            }

            let finalAlias: EntityAlias
            if let o = owner {
                finalAlias = try merged(try baseKey.alias.appendingVariant(o), with: a)
            } else {
                finalAlias = try merged(baseKey.alias, with: a)
            }

            let unitKey = try EntityKey(class: baseKey.class, family: baseKey.family, alias: finalAlias)
            var mergedMeta = metadata
            if let d = details { mergedMeta["details"] = d }

            out.append(EntityDef(
                key: unitKey,
                displayName: displayName,
                metadata: mergedMeta,
                profile: profile,
                depreciation: nil,
                depreciationDraft: dep,
                kia: nil,
                kiaDraft: kiaDraft,
            ))
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
