import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseVATBlock() throws -> VATAnnotation {
        try expectKeywordOrIdent("vat")
        try beginBlock()

        var kind: VATKind?
        var period: VATPeriod?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("kind"), .ident("kind"):
                guard kind == nil else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single kind field",
                        at: loc()
                    )
                }

                try expectFieldEquals("kind")
                kind = try parseVATKindValue()

            case .keyword("period"), .ident("period"):
                guard period == nil else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single period block",
                        at: loc()
                    )
                }

                period = try parseVATPeriodBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "kind|period|}",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let kind else {
            throw ParserError.unexpectedToken(
                current,
                expected: "kind",
                at: loc()
            )
        }

        guard let period else {
            throw ParserError.unexpectedToken(
                current,
                expected: "period",
                at: loc()
            )
        }

        return VATAnnotation(
            kind: kind,
            period: period
        )
    }

    @inlinable
    func parseVATPeriodBlock() throws -> VATPeriod {
        try expectKeywordOrIdent("period")
        try beginBlock()

        var year: Int?
        var quarter: VATQuarter?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("year"), .ident("year"):
                guard year == nil else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single year field",
                        at: loc()
                    )
                }

                try expectFieldEquals("year")
                year = try expectInteger()

            case .keyword("quarter"), .ident("quarter"):
                guard quarter == nil else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "single quarter field",
                        at: loc()
                    )
                }

                try expectFieldEquals("quarter")
                quarter = try parseVATQuarterValue()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "year|quarter|}",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let year else {
            throw ParserError.unexpectedToken(
                current,
                expected: "year",
                at: loc()
            )
        }

        guard let quarter else {
            throw ParserError.unexpectedToken(
                current,
                expected: "quarter",
                at: loc()
            )
        }

        return VATPeriod(
            year: year,
            quarter: quarter
        )
    }

    @inlinable
    func parseVATKindValue() throws -> VATKind {
        let raw: String

        switch current {
        case let .ident(s), let .keyword(s), let .string(s):
            raw = s.trimmingCharacters(in: .whitespacesAndNewlines)
            advance()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "filing|payment|refund|correction",
                at: loc()
            )
        }

        switch raw.lowercased() {
        case "filing":
            return .filing

        case "payment":
            return .payment

        case "refund":
            return .refund

        case "correction":
            return .correction

        default:
            throw ParserError.unexpectedToken(
                .ident(raw),
                expected: "filing|payment|refund|correction",
                at: loc()
            )
        }
    }

    @inlinable
    func parseVATQuarterValue() throws -> VATQuarter {
        let rawQuarter = try expectInteger()

        switch rawQuarter {
        case 1:
            return .q1

        case 2:
            return .q2

        case 3:
            return .q3

        case 4:
            return .q4

        default:
            throw ParserError.unexpectedToken(
                .number(Decimal(rawQuarter)),
                expected: "1|2|3|4",
                at: loc()
            )
        }
    }
}
