import Foundation
import Accounting

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

        while current != .rBrace && current != .eof {
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

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "profile / use alias / details / metadata / depreciation / type / domain / content / ownership / rollforward / variant / unit",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

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

        return DepreciationConfigDraft(
            residualPercentage: residualPercentage,
            accountRef: accountRef,
            contraRef: contraRef,
            method: method,
            usefulLifeYears: usefulLifeYears
        )
    }
}
