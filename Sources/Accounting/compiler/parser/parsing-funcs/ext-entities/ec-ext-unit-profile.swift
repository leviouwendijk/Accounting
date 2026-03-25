import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseEntityUnitProfileBlock(
        tz: TimeZone
    ) throws -> EntityUnitProfile {
        try expect(.lBrace)

        var acquisitionDate: Date?
        var commissionDate: Date?
        var acquisitionCost: AssetAcquisitionCost?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("acquisition_date"), .keyword("acquisition_date"):
                advance()
                acquisitionDate = try parseDateBlock(tz: tz)

            case .ident("commission_date"), .keyword("commission_date"):
                advance()
                commissionDate = try parseDateBlock(tz: tz)

            case .ident("valuation"), .keyword("valuation"):
                advance()
                acquisitionCost = try parseValuationAcquisitionCostBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "acquisition_date / commission_date / valuation",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        return EntityUnitProfile(
            acquisitionDate: acquisitionDate,
            commissionDate: commissionDate,
            acquisitionCost: acquisitionCost
        )
    }
}
