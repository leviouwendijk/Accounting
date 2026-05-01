import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseEntityUnitProfileBlock(
        tz: TimeZone
    ) throws -> EntityUnitProfile {
        try expect(.lBrace)

        var acquisition: AssetAcquisitionProfile?
        var commissionDate: Date?

        var legacyAcquisitionDate: Date?
        var legacyAcquisitionCost: AssetAcquisitionCost?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("acquisition"), .keyword("acquisition"):
                advance()
                let parsed = try parseAssetAcquisitionProfileBlock(tz: tz)

                if acquisition == nil {
                    acquisition = parsed
                } else {
                    if acquisition?.date == nil {
                        acquisition?.date = parsed.date
                    }
                    if acquisition?.entry == nil {
                        acquisition?.entry = parsed.entry
                    }
                    if acquisition?.account == nil {
                        acquisition?.account = parsed.account
                    }
                    if acquisition?.valuation == nil {
                        acquisition?.valuation = parsed.valuation
                    }
                }

            case .ident("acquisition_date"), .keyword("acquisition_date"):
                advance()
                legacyAcquisitionDate = try parseDateBlock(tz: tz)

            case .ident("commission_date"), .keyword("commission_date"):
                advance()
                commissionDate = try parseDateBlock(tz: tz)

            case .ident("valuation"), .keyword("valuation"):
                advance()
                legacyAcquisitionCost = try parseValuationAcquisitionCostBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "acquisition / acquisition_date / commission_date / valuation",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        if acquisition == nil {
            acquisition = AssetAcquisitionProfile(
                date: legacyAcquisitionDate,
                valuation: legacyAcquisitionCost
            )
        } else {
            if acquisition?.date == nil {
                acquisition?.date = legacyAcquisitionDate
            }
            if acquisition?.valuation == nil {
                acquisition?.valuation = legacyAcquisitionCost
            }
        }

        if acquisition?.date == nil &&
            acquisition?.entry == nil &&
            acquisition?.account == nil &&
            acquisition?.valuation == nil {
            acquisition = nil
        }

        return EntityUnitProfile(
            acquisition: acquisition,
            commissionDate: commissionDate
        )
    }
}

// public extension EntryCompilerParsing {
//     @inlinable
//     func parseEntityUnitProfileBlock(
//         tz: TimeZone
//     ) throws -> EntityUnitProfile {
//         try expect(.lBrace)

//         var acquisitionDate: Date?
//         var commissionDate: Date?
//         var acquisitionCost: AssetAcquisitionCost?

//         while current != .rBrace && current != .eof {
//             switch current {
//             case .ident("acquisition_date"), .keyword("acquisition_date"):
//                 advance()
//                 acquisitionDate = try parseDateBlock(tz: tz)

//             case .ident("commission_date"), .keyword("commission_date"):
//                 advance()
//                 commissionDate = try parseDateBlock(tz: tz)

//             case .ident("valuation"), .keyword("valuation"):
//                 advance()
//                 acquisitionCost = try parseValuationAcquisitionCostBlock()

//             default:
//                 throw ParserError.unexpectedToken(
//                     current,
//                     expected: "acquisition_date / commission_date / valuation",
//                     at: loc()
//                 )
//             }
//         }

//         try expect(.rBrace)

//         return EntityUnitProfile(
//             acquisitionDate: acquisitionDate,
//             commissionDate: commissionDate,
//             acquisitionCost: acquisitionCost
//         )
//     }
// }
