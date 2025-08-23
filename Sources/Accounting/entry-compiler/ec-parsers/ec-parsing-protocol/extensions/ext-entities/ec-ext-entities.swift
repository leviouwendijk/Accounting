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
            if parseTypeDirective(into: &metadata) { continue }
            if parseDomainDirective(into: &metadata) { continue }
            if parseContentBlock(into: &metadata) { continue }
            if parseOwnershipBlock(into: &metadata) { continue }

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

            case .ident("display_name"):
                advance(); try expect(.equals)
                guard case let .string(s) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                }
                displayName = s; advance()

            case .ident("metadata"), .keyword("metadata"):
                metadata = try parseStringMapBlock(named: "metadata")

            case .ident("depreciation"):
                // IMPORTANT: pass metadata sink so rollforward/valuation are captured
                dep = try parseDepreciationBlock(meta: &metadata)

            // Nested blocks that produce additional concrete aliases
            case .keyword("variant"), .ident("variant"):
                guard let k = key else {
                    throw ParserError.unexpectedToken(current, expected: "use alias before variant", at: loc())
                }
                extraDefs.append(contentsOf: try parseVariantBlocks(baseKey: k))

            case .keyword("unit"), .ident("unit"):
                guard let k = key else {
                    throw ParserError.unexpectedToken(current, expected: "use alias before unit", at: loc())
                }
                extraDefs.append(contentsOf: try parseUnitBlocks(baseKey: k))

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
        defs.append(EntityDef(key: k, displayName: displayName, metadata: metadata, depreciation: dep))
        defs.append(contentsOf: extraDefs)
        return defs
    }
}
