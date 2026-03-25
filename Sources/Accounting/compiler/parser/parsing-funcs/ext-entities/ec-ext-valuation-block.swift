import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseValuationAcquisitionCostBlock() throws -> AssetAcquisitionCost {
        try expect(.lBrace)

        var acquisition: AssetAcquisitionCost?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("acquisition_cost"), .keyword("acquisition_cost"):
                advance()
                acquisition = try parseAcquisitionCostBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "acquisition_cost or '}'",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        guard let acquisition else {
            throw ParserError.unexpectedToken(
                current,
                expected: "valuation.acquisition_cost",
                at: loc()
            )
        }

        return acquisition
    }

    @inlinable
    func parseAcquisitionCostBlock() throws -> AssetAcquisitionCost {
        try expect(.lBrace)

        var direct: Decimal?
        var indirect: Decimal = 0

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("direct"), .keyword("direct"):
                advance()
                try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "number",
                        at: loc()
                    )
                }
                direct = n
                advance()

            case .ident("indirect"), .keyword("indirect"):
                advance()
                try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "number",
                        at: loc()
                    )
                }
                indirect = n
                advance()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "direct|indirect or '}'",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        guard let direct else {
            throw ParserError.unexpectedToken(
                current,
                expected: "direct",
                at: loc()
            )
        }

        return AssetAcquisitionCost(
            direct: direct,
            indirect: indirect
        )
    }
}
