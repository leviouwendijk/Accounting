import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseAssetAcquisitionProfileBlock(
        tz: TimeZone
    ) throws -> AssetAcquisitionProfile {
        try expect(.lBrace)

        var date: Date?
        var entry: Int?
        var account: AccountRef?
        var valuation: AssetAcquisitionCost?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("date"), .keyword("date"),
                 .ident("effective_date"), .keyword("effective_date"),
                 .ident("acquisition_date"), .keyword("acquisition_date"):
                advance()
                date = try parseDateBlock(tz: tz)

            case .ident("entry"), .keyword("entry"):
                advance()
                try expect(.equals)

                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "number",
                        at: loc()
                    )
                }

                entry = (n as NSDecimalNumber).intValue
                advance()

            case .ident("account"), .keyword("account"):
                advance()
                try expect(.equals)
                account = try parseAccountRefFlexible()

            case .ident("valuation"), .keyword("valuation"):
                advance()
                valuation = try parseValuationAcquisitionCostBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "date / effective_date / acquisition_date / entry / account / valuation",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        return AssetAcquisitionProfile(
            date: date,
            entry: entry,
            account: account,
            valuation: valuation
        )
    }
}
