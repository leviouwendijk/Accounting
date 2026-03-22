import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseDepreciationBlock(
        meta: inout [String: String],
        tz: TimeZone
    ) throws -> DepreciationConfigDraft {
        guard current == .keyword("depreciation") || current == .ident("depreciation") else {
            throw ParserError.unexpectedToken(
                current,
                expected: "depreciation",
                at: loc()
            )
        }

        advance()
        try expect(.lBrace)

        var method: DepreciationMethod?
        var usefulLifeYears: Decimal?
        var residualPercentage: Decimal = 0
        var accountRef: AccountRef?
        var contraRef: AccountRef?

        // deprecated compatibility only
        var schedule: DepreciationScheduleSetting?
        var acquisition: AssetAcquisitionCost?

        while current != .rBrace && current != .eof {
            if try parseDepreciationValuation(into: &meta) {
                let direct = Decimal(string: meta["dep.valuation.acquisition.direct"] ?? "0") ?? 0
                let indirect = Decimal(string: meta["dep.valuation.acquisition.indirect"] ?? "0") ?? 0
                acquisition = AssetAcquisitionCost(
                    direct: direct,
                    indirect: indirect
                )
                continue
            }

            if try parseUsefulLifeMonths(into: &meta) {
                continue
            }

            if try parseDepreciationRollforward(into: &meta, tz: tz) {
                continue
            }

            if try parseResidualValue(into: &meta, capturePercentInto: &residualPercentage) {
                continue
            }

            switch current {
            case .ident("method"), .keyword("method"):
                advance()
                try expect(.equals)

                let rawMethod: String
                switch current {
                case let .ident(value), let .keyword(value):
                    rawMethod = value
                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "sl|straight_line|ddb|syd|uop",
                        at: loc()
                    )
                }

                guard let parsed = DepreciationMethod(rawValue: rawMethod) else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "sl|straight_line|ddb|syd|uop",
                        at: loc()
                    )
                }

                method = parsed.canonical
                meta["dep.method"] = parsed.canonical.rawValue
                advance()

            default:
                break
            }

            switch current {
            case .ident("method"), .keyword("method"):
                advance()
                try expect(.equals)

                let rawMethod: String
                switch current {
                case let .ident(value), let .keyword(value):
                    rawMethod = value
                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "sl|straight_line|ddb|syd|uop",
                        at: loc()
                    )
                }

                guard let parsed = DepreciationMethod(rawValue: rawMethod) else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "sl|straight_line|ddb|syd|uop",
                        at: loc()
                    )
                }

                method = parsed.canonical
                meta["dep.method"] = parsed.canonical.rawValue
                advance()

            case .ident("useful_life_years"), .keyword("useful_life_years"),
                 .ident("useful_life"), .keyword("useful_life"):
                advance()
                try expect(.equals)

                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "number",
                        at: loc()
                    )
                }

                usefulLifeYears = n
                meta["dep.useful_life_years"] = "\(n)"
                advance()

            case .ident("commission_date"), .keyword("commission_date"),
                 .ident("effective_date"), .keyword("effective_date"),
                 .ident("date"), .keyword("date"):
                let (_, spec) = try parseNamedDateOrInferExpecting(
                    names: ["date", "effective_date", "commission_date"],
                    tz: tz,
                    allowInfer: false,
                    allowUnixEpoch: true
                )

                let effectiveDate = try spec.asAbsolute(loc: loc())

                if let method, let usefulLifeYears {
                    schedule = DepreciationScheduleSetting(
                        method: method,
                        usefulLifeYears: usefulLifeYears,
                        effectiveDate: effectiveDate
                    )
                } else {
                    meta["dep.effective_date"] = isoDate(effectiveDate)
                    schedule = DepreciationScheduleSetting(
                        method: .straight_line,
                        usefulLifeYears: usefulLifeYears ?? 0,
                        effectiveDate: effectiveDate
                    )
                }

            case .ident("account"), .keyword("account"):
                advance()
                try expect(.equals)
                accountRef = try parseAccountRefFlexible()
                meta["dep.account.ref"] = accountRef?.debugString ?? "<ref>"

            case .ident("contra"), .keyword("contra"),
                 .ident("contra_account"), .keyword("contra_account"):
                advance()
                try expect(.equals)
                contraRef = try parseAccountRefFlexible()
                meta["dep.account.contra.ref"] = contraRef?.debugString ?? "<ref>"

            case .ident("valuation"), .keyword("valuation"):
                advance()
                acquisition = try parseValuationAcquisitionCostBlock()
                meta["dep.valuation.acquisition.direct"] = "\(acquisition?.direct ?? 0)"
                meta["dep.valuation.acquisition.indirect"] = "\(acquisition?.indirect ?? 0)"

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "profile / use alias / details / metadata / depreciation / type / domain / content / ownership / rollforward / variant / unit",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        if acquisition == nil {
            let direct = Decimal(string: meta["dep.valuation.acquisition.direct"] ?? "0") ?? 0
            let indirect = Decimal(string: meta["dep.valuation.acquisition.indirect"] ?? "0") ?? 0
            acquisition = AssetAcquisitionCost(
                direct: direct,
                indirect: indirect
            )
        }

        guard let method else {
            throw ParserError.unexpectedToken(
                current,
                expected: "depreciation.method",
                at: loc()
            )
        }

        guard let usefulLifeYears else {
            throw ParserError.unexpectedToken(
                current,
                expected: "depreciation.useful_life",
                at: loc()
            )
        }

        guard let accountRef else {
            throw ParserError.unexpectedToken(
                current,
                expected: "depreciation.account",
                at: loc()
            )
        }

        guard let contraRef else {
            throw ParserError.unexpectedToken(
                current,
                expected: "depreciation.contra",
                at: loc()
            )
        }

        let finalSchedule: DepreciationScheduleSetting? = {
            if let schedule {
                return DepreciationScheduleSetting(
                    method: method,
                    usefulLifeYears: usefulLifeYears,
                    effectiveDate: schedule.effectiveDate
                )
            }
            return nil
        }()

        return DepreciationConfigDraft(
            schedule: finalSchedule,
            acquisition: acquisition,
            residualPercentage: residualPercentage,
            accountRef: accountRef,
            contraRef: contraRef,
            method: method,
            usefulLifeYears: usefulLifeYears
        )
    }
}

// public extension EntryCompilerParsing {
//     @inlinable
//     func parseDepreciationBlock(
//         // baseEntity: EntityKey,
//         meta: inout [String:String],
//         tz: TimeZone
//     ) throws -> DepreciationConfigDraft {
//         try expect(.keyword("depreciation"))
//         try expect(.lBrace)

//         var method: DepreciationMethod?
//         var lifeYears: Decimal?
//         var effective: Date?
//         var residualPercent: Decimal = 0
//         var acquisition = AssetAcquisitionCost(direct: 0)
//         var sawInlineAcquisition = false
//         var accountRef: AccountRef?
//         var contraRef: AccountRef?

//         while current != .rBrace && current != .eof {
//             if try parseDepreciationValuation(into: &meta) { // fills dep.valuation.acquisition.direct/indirect
//                 continue
//             }
//             if try parseUsefulLifeMonths(into: &meta) {      // fills dep.useful_life_months
//                 continue
//             }
//             if try parseDepreciationRollforward(into: &meta, tz: tz) { // stores dep.rollforward.* metadata
//                 continue
//             }
//             if try parseResidualValue(into: &meta, capturePercentInto: &residualPercent) {
//                 continue 
//             }

//             switch current {
//             case .ident("method"), .keyword("method"):
//                 advance(); try expect(.equals)
//                 guard case let .ident(m) = current,
//                       let mm = DepreciationMethod(rawValue: m) else {
//                     throw ParserError.unexpectedToken(current, expected: "sl|straight_line|ddb|syd|uop", at: loc())
//                 }
//                 method = mm.canonical
//                 meta["dep.method"] = mm.canonical.rawValue
//                 advance()

//             case .ident("useful_life_years"), .keyword("useful_life_years"),
//                  .ident("useful_life"),      .keyword("useful_life"):
//                 advance(); try expect(.equals)
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 lifeYears = n
//                 meta["dep.useful_life_years"] = "\(n)"
//                 advance()

//             case .ident("residual_percent"), .keyword("residual"), .ident("residual"):
//                 // allow: residual_percent = 10   OR   residual { percent = 10 }
//                 advance()
//                 if current == .equals {
//                     advance()
//                     guard case let .number(n) = current else {
//                         throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                     }
//                     residualPercent = n
//                     meta["dep.residual.percent"] = "\(n)"
//                     advance()
//                 } else {
//                     try expect(.lBrace)
//                     while current != .rBrace && current != .eof {
//                         guard case .ident("percent") = current else {
//                             throw ParserError.unexpectedToken(current, expected: "percent", at: loc())
//                         }
//                         advance(); try expect(.equals)
//                         guard case let .number(n) = current else {
//                             throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                         }
//                         residualPercent = n
//                         meta["dep.residual.percent"] = "\(n)"
//                         advance()
//                     }
//                     try expect(.rBrace)
//                 }

//             case .ident("effective_date"), .ident("date"), .keyword("date"),
//                  .keyword("effective_date"), .keyword("commission_date"):
//                 let (_, spec) = try parseNamedDateOrInferExpecting(
//                     names: ["date","effective_date","commission_date"],
//                     tz: tz,
//                     allowInfer: false,
//                     allowUnixEpoch: true
//                 )
//                 let d = try spec.asAbsolute(loc: loc())
//                 // use `d` (and/or persist ISO string)
//                 effective = d
//                 meta["dep.effective_date"] = isoDate(d)

//             case .ident("account"), .keyword("account"):
//                 advance(); try expect(.equals)
//                 accountRef = try parseAccountRefFlexible()
//                 // best-effort breadcrumb
//                 meta["dep.account.ref"] = accountRef?.debugString ?? "<ref>"

//             // in parseDepreciationBlock (…) where you already handle `account`
//             case .ident("contra"), .keyword("contra"),
//                  .ident("contra_account"), .keyword("contra_account"):
//                 advance(); try expect(.equals)
//                 contraRef = try parseAccountRefFlexible()
//                 meta["dep.account.contra.ref"] = contraRef?.debugString ?? "<ref>"

//             case .ident("acquisition"), .keyword("acquisition"):
//                 advance(); try expect(.lBrace)
//                 var direct: Decimal?; var indirect: Decimal = 0
//                 while current != .rBrace && current != .eof {
//                     switch current {
//                     case .ident("direct"):
//                         advance(); try expect(.equals)
//                         guard case let .number(n) = current else {
//                             throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                         }
//                         direct = n; advance()
//                     case .ident("indirect"):
//                         advance(); try expect(.equals)
//                         guard case let .number(n) = current else {
//                             throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                         }
//                         indirect = n; advance()
//                     default:
//                         throw ParserError.unexpectedToken(current, expected: "direct/indirect", at: loc())
//                     }
//                 }
//                 try expect(.rBrace)
//                 acquisition = AssetAcquisitionCost(direct: direct ?? 0, indirect: indirect)
//                 sawInlineAcquisition = true
//                 // mirror to meta for consistency with valuation parser
//                 meta["dep.valuation.acquisition.direct"] = "\(acquisition.direct)"
//                 meta["dep.valuation.acquisition.indirect"] = "\(acquisition.indirect)"

//             default:
//                 throw ParserError.unexpectedToken(
//                     current,
//                     expected: "method / useful_life(_years) / residual[_percent] / date / account / acquisition / valuation / rollforward",
//                     at: loc()
//                 )
//             }
//         }
//         try expect(.rBrace)

//         if !sawInlineAcquisition {
//             let d = Decimal(string: meta["dep.valuation.acquisition.direct"] ?? "0") ?? 0
//             let i = Decimal(string: meta["dep.valuation.acquisition.indirect"] ?? "0") ?? 0
//             acquisition = AssetAcquisitionCost(direct: d, indirect: i)
//         }

//         guard
//             let m = method,
//             let y = lifeYears,
//             let eff = effective,
//             let a = accountRef,
//             let c = contraRef
//         else {
//             throw ParserError.unexpectedToken(current, expected: "complete depreciation block", at: loc())
//         }

//         return DepreciationConfigDraft(
//             schedule: .init(method: m, usefulLifeYears: y, effectiveDate: eff),
//             acquisition: acquisition,
//             residualPercentage: residualPercent,
//             accountRef: a,
//             contraRef: c
//         )
//     }
// }
