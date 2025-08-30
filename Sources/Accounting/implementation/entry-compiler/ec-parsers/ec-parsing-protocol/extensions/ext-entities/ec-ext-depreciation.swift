import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseDepreciationBlock(
        meta: inout [String:String],
        tz: TimeZone
    ) throws -> DepreciationConfig {

        advance() // 'depreciation'
        try expect(.lBrace)

        // Gather into locals first (no placeholders in the model)
        var method: DepreciationMethod?
        var lifeYears: Decimal?
        // var lifeMonths: Decimal?
        var effectiveDate: Date?
        var residualPercent: Decimal?
        var residualAmount: Decimal?
        // var _sawKeepPercentageFlag = false // legacy no-op

        while current != .rBrace && current != .eof {
            if try parseDepreciationValuation(into: &meta) { continue }          // fills dep.valuation.acquisition.*
            if try parseUsefulLifeMonths(into: &meta) { continue }               // fills dep.useful_life_months
            if try parseDepreciationRollforward(into: &meta, tz: tz) { continue }

            switch current {
            case .ident("method"), .keyword("method"):
                advance(); try expect(.equals)
                guard case let .ident(m) = current,
                      let mm = DepreciationMethod(rawValue: m) else {
                    throw ParserError.unexpectedToken(current, expected: "straight_line|sl|ddb|syd|uop", at: loc())
                }
                method = mm.canonical
                advance()

            case .ident("useful_life_years"), .keyword("useful_life_years"),
                 .ident("useful_life"),      .keyword("useful_life"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                lifeYears = n
                advance()

            case .ident("residual_value"), .keyword("residual_value"):
                advance(); try expect(.lBrace)
                while current != .rBrace && current != .eof {
                    switch current {
                    // case .ident("keep_percentage"), .keyword("keep_percentage"):
                    //     _sawKeepPercentageFlag = true   // legacy, treated as no-op
                    //     advance()

                    case .ident("percentage"), .keyword("percentage"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        residualPercent = n; advance()

                    case .ident("amount"), .keyword("amount"),
                         .ident("value"),  .keyword("value"):
                        advance(); try expect(.equals)
                        guard case let .number(n) = current else {
                            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                        }
                        residualAmount = n; advance()

                    default:
                        // allow trailing commas, whitespace, etc.
                        break
                    }
                }
                try expect(.rBrace)

            case .ident("effective_date"), .keyword("effective_date"),
                 .ident("commission_date"), .keyword("commission_date"):
                let (_, spec) = try parseNamedDateOrInferExpecting(
                    names: ["effective_date","commission_date"],
                    tz: tz,
                    allowInfer: false
                )
                effectiveDate = try spec.asAbsolute(loc: loc())

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "method/useful_life(_years)/residual_value/effective_date/valuation/rollforward",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        // Derive acquisition cost from metadata parsed by valuation block
        let direct = Decimal(string: meta["dep.valuation.acquisition.direct"] ?? "0") ?? 0
        let indirect = Decimal(string: meta["dep.valuation.acquisition.indirect"] ?? "0") ?? 0
        let acquisition = AssetAcquisitionCost(direct: direct, indirect: indirect)  // new model, non-optional :contentReference[oaicite:3]{index=3}

        // Fallback: useful_life_months → years
        if lifeYears == nil, let mStr = meta["dep.useful_life_months"], let m = Decimal(string: mStr) {
            lifeYears = m / 12
        }

        // Compute residual percent if only amount was provided.
        // Model accepts 0–1 or 0–100; we choose 0–1 here.
        let finalResidualPercent: Decimal = {
            if let p = residualPercent { return p }
            if let amt = residualAmount, acquisition.cost > 0 { return amt / acquisition.cost }
            return 0
        }()

        // Require mandatory pieces (the new config is non-optional) :contentReference[oaicite:4]{index=4}
        guard let m = method else {
            throw ParserError.unexpectedToken(current, expected: "depreciation.method", at: loc())
        }
        guard let y = lifeYears else {
            throw ParserError.unexpectedToken(current, expected: "useful_life_years or useful_life_months", at: loc())
        }
        guard let eff = effectiveDate else {
            throw ParserError.unexpectedToken(current, expected: "effective_date", at: loc())
        }

        let cfg = DepreciationConfig(
            method: m,
            acquisitionCost: acquisition,
            usefulLifeYears: y,
            residualPercentage: finalResidualPercent,
            effectiveDate: eff
        ) // builds schedule/acquisition/residual (strong, non-optional) :contentReference[oaicite:5]{index=5}

        // Strong safety: run model-level validation too
        try cfg.validate()  // validates life, percent, and residual vs cost. :contentReference[oaicite:6]{index=6}
        return cfg
    }
}


// public extension EntryCompilerParsing {
//     @inlinable
//     func parseDepreciationBlock(
//         meta: inout [String:String],
//         tz: TimeZone
//     ) throws -> DepreciationConfig {
//         var out = DepreciationConfig(
//             method: nil,
//             usefulLifeYears: nil,
//             residualValuePercent: 0,
//             residualValueAmount: nil,
//             effectiveDate: nil
//         )

//         advance() // 'depreciation'
//         try expect(.lBrace)

//         while current != .rBrace && current != .eof {
//             if try parseDepreciationValuation(into: &meta) { continue }
//             if try parseUsefulLifeMonths(into: &meta) { continue }
//             if try parseDepreciationRollforward(into: &meta, tz: tz) { continue }

//             switch current {
//             case .ident("method"), .keyword("method"):
//                 advance(); try expect(.equals)
//                 guard case let .ident(m) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "dep method", at: loc())
//                 }
//                 guard let mm = DepreciationMethod(rawValue: m) else {
//                     throw ParserError.unexpectedToken(current, expected: "straight_line|sl|ddb|syd|uop", at: loc())
//                 }
//                 out.method = mm
//                 advance()

//             case .ident("useful_life_years"), .keyword("useful_life_years"),
//                 .ident("useful_life"),        .keyword("useful_life"):
//                 advance(); try expect(.equals)
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 out.usefulLifeYears = n
//                 advance()

//             case .ident("residual_value"), .keyword("residual_value"):
//                 advance(); try expect(.lBrace)
//                 while current != .rBrace && current != .eof {
//                     switch current {
//                     case .ident("keep_percentage"), .keyword("keep_percentage"):
//                         advance(); out.residualValuePercent = Decimal(-1)
//                     case .ident("percentage"), .keyword("percentage"):
//                         advance(); try expect(.equals)
//                         guard case let .number(n) = current else {
//                             throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                         }
//                         out.residualValuePercent = n; advance()
//                     case .ident("amount"), .keyword("amount"), .ident("value"), .keyword("value"):
//                         advance(); try expect(.equals)
//                         guard case let .number(n) = current else {
//                             throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                         }
//                         out.residualValueAmount = n; advance()
//                     default:
//                         break
//                     }
//                 }
//                 try expect(.rBrace)

//             case .ident("effective_date"), .keyword("effective_date"),
//                  .ident("commission_date"), .keyword("commission_date"):
//                 let (_, spec) = try parseNamedDateOrInferExpecting(
//                     names: ["effective_date","commission_date"],
//                     tz: tz,
//                     allowInfer: false
//                 )
//                 out.effectiveDate = try spec.asAbsolute(loc: loc())

//             default:
//                 throw ParserError.unexpectedToken(
//                     current,
//                     expected: "method/useful_life(_years)/residual_value/effective_date/valuation/rollforward",
//                     at: loc()
//                 )
//             }
//         }

//         try expect(.rBrace)
//         return out
//     }

//     // // back-compat shim (if any callsites still use the old signature)
//     // @inlinable
//     // func parseDepreciationBlock() throws -> DepreciationConfig {
//     //     var sink: [String:String] = [:]
//     //     return try parseDepreciationBlock(meta: &sink)
//     // }
// }
