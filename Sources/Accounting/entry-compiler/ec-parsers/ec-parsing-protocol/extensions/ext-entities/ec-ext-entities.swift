import Foundation
import plate

public extension EntryCompilerParsing {
    /// Provide inferredClass/family from file path; if nil after parsing → error.
    /// Supports:
    ///   use alias (objects.storable.macbook)
    ///   use alias (macbook)                  // requires both inferred
    ///   use alias (objects.macbook)          // requires inferred family
    @inlinable
    func parseEntityBlock(inferredClass: String?, inferredFamily: String?) throws -> EntityDef {
        try expect(.keyword("entity"))
        try expect(.lBrace)

        var key: EntityKey?
        var displayName: String?
        var metadata: [String:String] = [:]
        var dep: DepreciationConfig?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("use"):
                advance()
                try expect(.keyword("alias"))
                // Accept 1..3 segments; normalize unit(...) → "#..."
                let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)

                let ref = try makeEntityRef(from: segs)
                // Coalesce with inferred pieces
                let c = ref.`class` ?? inferredClass
                let f = ref.family ?? inferredFamily
                guard let cls = c, let fam = f else {
                    throw ParserError.unexpectedToken(current, expected: "class/family must be present or inferrable from path", at: loc())
                }
                key = EntityKey(class: cls, family: fam, alias: ref.alias)

            case .ident("display_name"):
                advance(); try expect(.equals)
                guard case let .string(s) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                }
                displayName = s; advance()

            case .ident("meta"), .keyword("metadata"):
                advance(); try expect(.lBrace)
                while current != .rBrace && current != .eof {
                    guard case let .ident(k) = current else { break }
                    advance(); try expect(.equals)
                    guard case let .string(v) = current else {
                        throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                    }
                    metadata[k] = v; advance()
                }
                try expect(.rBrace)

            case .ident("depreciation"):
                dep = try parseDepreciationBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "use alias / display_name / metadata / depreciation", at: loc())
            }
        }

        try expect(.rBrace)
        guard let k = key else {
            throw ParserError.unexpectedToken(current, expected: "use alias (<class[.family].alias>)", at: loc())
        }
        return EntityDef(key: k, displayName: displayName, metadata: metadata, depreciation: dep)
    }

    @inlinable
    func parseDepreciationBlock() throws -> DepreciationConfig {
        var out = DepreciationConfig(
            method: nil,
            usefulLifeYears: nil,
            residualValuePercent: 0,
            residualValueAmount: nil,
            effectiveDate: nil
        )

        advance() // 'depreciation'
        try expect(.lBrace)

        while current != .rBrace && current != .eof {
            switch current {

            case .ident("method"):
                advance(); try expect(.equals)
                guard case let .ident(m) = current else {
                    throw ParserError.unexpectedToken(current, expected: "dep method", at: loc())
                }
                guard let mm = DepreciationMethod(rawValue: m) else {
                    throw ParserError.unexpectedToken(current, expected: "straight_line|sl|ddb|syd|uop", at: loc())
                }
                out.method = mm
                advance()

            case .ident("useful_life_years"), .ident("useful_life"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                out.usefulLifeYears = n
                advance()

            case .ident("residual_value"):
                advance(); try expect(.lBrace)
                while current != .rBrace && current != .eof {
                    switch current {
                    case .ident("keep_percentage"):
                        advance()
                        out.residualValuePercent = Decimal(-1) // sentinel

                    case .ident("percentage"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        out.residualValuePercent = n; advance()

                    case .ident("amount"), .ident("value"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        out.residualValueAmount = n; advance()

                    default:
                        // tolerate unknowns? otherwise:
                        break
                    }
                }
                try expect(.rBrace)

            case .ident("effective_date"), .ident("commission_date"):
                advance(); try expect(.equals)
                switch current {
                case let .dateLiteral(text):
                    // reuse your literal parser (uses plate); pick a neutral tz
                    out.effectiveDate = try parseDateLiteral(text, in: .current); advance()
                case .lBrace:
                    out.effectiveDate = try parseDateBlock(tz: .current)
                default:
                    throw ParserError.unexpectedToken(current, expected: "date literal or { … }", at: loc())
                }

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "method/useful_life(_years)/residual_value/effective_date",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        return out
    }
}
