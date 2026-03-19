// import Foundation

// public struct EquityAllocations: Sendable, Codable {
//     public var investedCapitalInterest: Decimal   // BEivKapOndRgv
//     public var laborCompensation: Decimal         // BEivKapOndArb
//     public var outsideCapitalComp: Decimal        // BEivKapOndVbv
//     public var profitShare: Decimal               // BEivKapOndAow
//     public var other: Decimal                     // BEivKapOndOvm
//     public var total: Decimal {
//         investedCapitalInterest + laborCompensation + outsideCapitalComp + profitShare + other
//     }
// }

// public struct EquityBreakdown: Sendable, Codable {
//     /// contributions by subcode (e.g. BEivKapPrsPsk, ...Pzl, ...Ops)
//     public var contributionsByCode: [String: Decimal]
//     /// drawings by subcode (Pro* plus Poc/Png/Pbe/Ppr)
//     public var drawingsByCode: [String: Decimal]
//     /// profit-allocation by subcode (Ond* except Beg)
//     public var allocationsByCode: [String: Decimal]
// }

// public struct EquityRollForward: Sendable, Codable {
//     public var opening: Decimal               // prior closing
//     public var openingPosted: Decimal         // BEivKapOndBeg in current period (not counted in movements)
//     public var contributions: Decimal         // sum of BEivKapPrs*
//     public var drawings: Decimal              // sum of BEivKapPro* + Poc + Png + Pbe + Ppr
//     public var allocations: EquityAllocations // Rgv/Arb/Vbv/Aow/Ovm
//     public var other: Decimal                 // residual movements under BEivKap not in groups above (Beg excluded)
//     public var closing: Decimal               // current equity total (BEivKap*)

//     /// Optional drilldown you can show/hide in UI.
//     public var details: EquityBreakdown?
// }

// public struct EquityOverview: Sendable, Codable {
//     public let period: ClosedRange<Date>
//     public let equityRootCode: String
//     public let perOwner: [EntityKey: EquityRollForward]
//     public let total: EquityRollForward

//     /// If provided, any BEivKap* codes that weren’t captured by known groups (with signed amounts).
//     public let uncapturedAudit: [String: Decimal]?
// }

// public enum EquityCodes {
//     public static let root = "BEivKap"

//     // “Ondernemingsvermogen …” subtree
//     public static let ondRoot = "BEivKapOnd"
//     public static let ondBeg  = "BEivKapOndBeg"
//     public static let ondRgv  = "BEivKapOndRgv"
//     public static let ondArb  = "BEivKapOndArb"
//     public static let ondVbv  = "BEivKapOndVbv"
//     public static let ondAow  = "BEivKapOndAow"
//     public static let ondOvm  = "BEivKapOndOvm"

//     // Contributions
//     public static let prsRoot = "BEivKapPrs" // includes Psk…Ops… etc.

//     // Drawings (two branches + “shortcut” codes)
//     public static let proRoot = "BEivKapPro" // includes Pmv/Prg/Piz/Ppr/Pri/Per/Prk/For/Ovp…
//     public static let poc     = "BEivKapPoc"
//     public static let png     = "BEivKapPng"
//     public static let pbe     = "BEivKapPbe"
//     public static let ppr     = "BEivKapPpr"
// }

