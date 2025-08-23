import Foundation

public extension EntryCompilerParsing {
    // unit { use alias <id>; [details {…}] [metadata {…}] [depreciation {…}] }
    @inlinable
    func parseUnitBlocks(baseKey: EntityKey) throws -> [EntityDef] {
        var out: [EntityDef] = []

        while current == .keyword("unit") || current == .ident("unit") {
            advance()
            try expect(.lBrace)

            var alias: EntityAlias?
            var displayName: String?
            var metadata: [String:String] = [:]   // ensure we have a sink here
            var details: String?
            var dep: DepreciationConfig?

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("use"):
                    advance(); try expect(.keyword("alias"))
                    // (alias) or bare
                    let segs: [String] = (current == .lPar)
                        ? ({ let (_, s) = try! readSegmentsUntilRPar(allowAllAsAlias: true); return s })()
                        : readFlatSegments()
                    guard let last = segs.last else {
                        throw ParserError.unexpectedToken(current, expected: "unit alias", at: loc())
                    }
                    alias = EntityAlias.parse(last)

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

                case .ident("depreciation"):
                    // FIX: pass metadata sink so valuation/rollforward etc land in meta
                    dep = try parseDepreciationBlock(meta: &metadata)

                default:
                    throw ParserError.unexpectedToken(current, expected: "use alias / metadata / details / depreciation", at: loc())
                }
            }

            try expect(.rBrace)

            guard let a = alias else {
                throw ParserError.unexpectedToken(current, expected: "unit { use alias ... }", at: loc())
            }

            let unitKey = EntityKey(class: baseKey.`class`, family: baseKey.family, alias: a)
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
