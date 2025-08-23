import Foundation
import plate

public extension EntryCompilerParsing {
    @inlinable
    func parseEntityBlock(fileURL: URL?) throws -> [EntityDef] {   // RETURN ARRAY
        let (ic, ifa) = fileURL.map(inferClassFamily) ?? (nil, nil)
        return try parseEntityBlock(inferredClass: ic, inferredFamily: ifa)
    }

    @inlinable
    func parseEntityBlock(inferredClass: String?, inferredFamily: String?) throws -> [EntityDef] { // RETURN ARRAY
        try expect(.keyword("entity"))
        try expect(.lBrace)

        var key: EntityKey?
        var displayName: String?
        var metadata: [String:String] = [:]
        var dep: DepreciationConfig?
        var extraDefs: [EntityDef] = []              // collect unit/variant outputs

        let hint = _entityPathHint(fileURL: nil, inferredClass: inferredClass, inferredFamily: inferredFamily)

        while current != .rBrace && current != .eof {
            // if parseTypeDirective(into: &metadata) { continue }
            // if parseDomainDirective(into: &metadata) { continue }
            // if parseContentBlock(into: &metadata) { continue }
            // if parseOwnershipBlock(into: &metadata) { continue }

            if parseTypeDirective(into: &metadata) { core.trace("  type → \(metadata["type"] ?? "")"); continue }
            if parseDomainDirective(into: &metadata) { core.trace("  domain.* set"); continue }
            if parseContentBlock(into: &metadata) { core.trace("  content.* set"); continue }
            if parseOwnershipBlock(into: &metadata) { core.trace("  ownership.* set"); continue }

            switch current {
            case .keyword("use"):
                advance()
                try expect(.keyword("alias"))

                let segs: [String]
                if current == .lPar {
                    let (_, s) = try readSegmentsUntilRPar(allowAllAsAlias: true)
                    segs = s
                } else {
                    segs = readFlatSegments()
                    guard !segs.isEmpty else {
                        throw ParserError.unexpectedToken(current, expected: "(<path>) or <alias>", at: loc())
                    }
                }

                let ref = try makeEntityRef(from: segs)
                let c = ref.`class` ?? inferredClass
                let f = ref.family ?? inferredFamily

                if c == nil {
                    throw InferenceError.missingEntityClass(
                        alias: ref.alias.string,
                        filePathHint: hint.replacingOccurrences(of: "<family>", with: f ?? "<family>"),
                        location: loc()
                    )
                }
                if f == nil {
                    throw InferenceError.missingEntityFamily(
                        alias: ref.alias.string,
                        filePathHint: hint.replacingOccurrences(of: "<class>", with: c ?? "<class>"),
                        location: loc()
                    )
                }
                key = EntityKey(class: c!, family: f!, alias: ref.alias)
                core.trace("  use alias \(ref.alias.string) → \(key!.identifier(displaying: .fullchain))")

            case .ident("details"), .keyword("details"):
                let txt = try parseFreeTextBlock(named: "details")
                metadata["details"] = txt
                core.trace("  details { … }")

            case .ident("display_name"):
                advance(); try expect(.equals)
                guard case let .string(s) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                }
                displayName = s; advance()
                core.trace("  display_name = \(s)")

            case .ident("metadata"), .keyword("metadata"):
                metadata = try parseStringMapBlock(named: "metadata")
                core.trace("  metadata { ... } (\(metadata.count) keys)")

            case .ident("depreciation"), .keyword("depreciation"):
                // IMPORTANT: pass metadata sink so rollforward/valuation are captured
                dep = try parseDepreciationBlock(meta: &metadata)
                core.trace("  depreciation { … }")

            // Nested blocks that produce additional concrete aliases
            case .keyword("variant"), .ident("variant"):
                guard let k = key else {
                    throw ParserError.unexpectedToken(current, expected: "use alias before variant", at: loc())
                }
                let defs = try parseVariantBlocks(baseKey: k)
                core.trace("  variant → +\(defs.count) def(s)")
                extraDefs.append(contentsOf: defs)

            case .keyword("unit"), .ident("unit"):
                guard let k = key else {
                    throw ParserError.unexpectedToken(current, expected: "use alias before unit", at: loc())
                }
                let defs = try parseUnitBlocks(baseKey: k)
                core.trace("  unit → +\(defs.count) def(s)")
                extraDefs.append(contentsOf: defs)

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "use alias / display_name / metadata / depreciation / type / domain / content / ownership / variant / unit",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        guard let k = key else {
            throw ParserError.unexpectedToken(current, expected: "use alias (<class[.family].alias>)", at: loc())
        }

        var defs: [EntityDef] = []
        let base = EntityDef(key: k, displayName: displayName, metadata: metadata, depreciation: dep)
        defs.append(base)
        defs.append(contentsOf: extraDefs)
        core.trace("  end entity → total \(defs.count) def(s)")
        return defs
    }
}
