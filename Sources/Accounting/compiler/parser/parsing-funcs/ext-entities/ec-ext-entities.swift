import Foundation
import plate

public extension EntryCompilerParsing {
    @inlinable
    func parseEntityBlock(
        fileURL: URL?,
        defaultTZ: TimeZone
    ) throws -> [EntityDef] {   // RETURN ARRAY
        let (ic, ifa) = fileURL.map(inferClassFamily) ?? (nil, nil)
        return try parseEntityBlock(inferredClass: ic, inferredFamily: ifa, defaultTZ: defaultTZ)
    }

    @inlinable
    func parseEntityBlock(
        inferredClass: String?,
        inferredFamily: String?,
        defaultTZ: TimeZone
    ) throws -> [EntityDef] { // RETURN ARRAY
        try expect(.keyword("entity"))
        try expect(.lBrace)

        var key: EntityKey?
        var displayName: String?
        var details: String?
        var metadata: [String:String] = [:]
        var dep: DepreciationConfigDraft?
        var extraDefs: [EntityDef] = []              // collect unit/variant outputs

        let hint = _entityPathHint(fileURL: nil, inferredClass: inferredClass, inferredFamily: inferredFamily)

        while current != .rBrace && current != .eof {
            if parseTypeDirective(into: &metadata) { 
                core.trace("  type → \(metadata["type"] ?? "")")
                continue 
            }

            if parseDomainDirective(into: &metadata) {
                core.trace("  domain.* set")
                continue 
            }

            if parseContentBlock(into: &metadata) {
                core.trace("  content.* set")
                continue 
            }

            if parseOwnershipBlock(into: &metadata, tz: defaultTZ) {
                core.trace("  ownership.* set")
                continue
            }

            if try parseOwnershipRollforward(into: &metadata, tz: defaultTZ) {
                core.trace("  ownership.rollforward { … }")
                continue
            }

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

            case .ident("display"), .keyword("display"):
                let txt = try parseFreeTextBlock(named: "display")
                displayName = txt
                core.trace("  display { … }")

            case .ident("details"), .keyword("details"):
                let txt = try parseFreeTextBlock(named: "details")
                details = txt
                metadata["details"] = txt
                core.trace("  details { … }")

            // case .ident("display_name"):
            //     advance(); try expect(.equals)
            //     guard case let .string(s) = current else {
            //         throw ParserError.unexpectedToken(current, expected: "string", at: loc())
            //     }
            //     displayName = s; advance()
            //     core.trace("  display_name = \(s)")

            case .ident("metadata"), .keyword("metadata"):
                metadata = try parseStringMapBlock(named: "metadata")
                core.trace("  metadata { ... } (\(metadata.count) keys)")

            case .ident("depreciation"), .keyword("depreciation"):
                dep = try parseDepreciationBlock(meta: &metadata, tz: defaultTZ)   // ← pass tz
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
                let defs = try parseUnitBlocks(baseKey: k, defaultTZ: defaultTZ)
                core.trace("  unit → +\(defs.count) def(s)")
                extraDefs.append(contentsOf: defs)

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "use alias / display / details / metadata / depreciation / type / domain / content / ownership / rollforward / variant / unit",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        guard let k = key else {
            throw ParserError.unexpectedToken(current, expected: "use alias (<class[.family].alias>)", at: loc())
        }

        var defs: [EntityDef] = []
        let oe = _ownerEquityFromMeta(metadata)
        let base = EntityDef(
            key: k,
            displayName: displayName,
            details: details,
            metadata: metadata,
            depreciation: nil,
            depreciationDraft: dep,
            ownerEquity: oe
        )
        defs.append(base)
        defs.append(contentsOf: extraDefs)
        core.trace("  end entity → total \(defs.count) def(s)")
        return defs
    }

    @inlinable
    func _ownerEquityFromMeta(_ meta: [String:String]) -> OwnerEquity? {
        let iso = ISO8601DateFormatter()

        // initial
        guard
            let d0s = meta["ownership.initial.date"], let d0 = iso.date(from: d0s),
            let p0s = meta["ownership.initial.pct"],  let p0 = Decimal(string: p0s)
        else {
            return nil // require both initial date & percentage to consider it present
        }

        let initial = OwnershipPercentage(date: d0, percentage: p0, details: meta["ownership.initial.details"])

        // changes: scan ownership.<idx>.(date|pct|reason)
        var changes: [OwnershipPercentage] = []

        // collect unique indices present
        var idxs = Set<Int>()
        for k in meta.keys where k.hasPrefix("ownership.") {
            let rest = k.dropFirst("ownership.".count) // e.g. "3.date"
            if let i = rest.split(separator: ".", maxSplits: 1).first, let n = Int(i) {
                idxs.insert(n)
            }
        }

        for i in idxs.sorted() {
            guard
                let ds = meta["ownership.\(i).date"], let d = iso.date(from: ds),
                let ps = meta["ownership.\(i).pct"],  let p = Decimal(string: ps)
            else { continue }
            let details = meta["ownership.\(i).reason"] ?? meta["ownership.\(i).details"]
            changes.append(OwnershipPercentage(date: d, percentage: p, details: details))
        }

        // sort just to be safe
        changes.sort { $0.date < $1.date }
        return OwnerEquity(initial: initial, changes: changes)
    }
}
