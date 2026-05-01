import Accounting
import Foundation

public struct PeriodRollforward: Sendable {
    public let asOf: Date
    public let owners: [Int]
    public let beginByOwner: [Int: Decimal]
    public let deltas: [Int: OwnerDelta]
    public let endByOwner: [Int: Decimal]
    public let niTotal: Decimal
    public let winstSource: WinstSource
    public let allocationNote: [Int: (percent: Decimal, amount: Decimal)]
    public let openingTotal: Decimal
    public let closingTotal: Decimal

    public init(
        asOf: Date,
        owners: [Int],
        beginByOwner: [Int: Decimal],
        deltas: [Int: OwnerDelta],
        endByOwner: [Int: Decimal],
        niTotal: Decimal,
        winstSource: WinstSource,
        allocationNote: [Int: (percent: Decimal, amount: Decimal)],
        openingTotal: Decimal,
        closingTotal: Decimal
    ) {
        self.asOf = asOf
        self.owners = owners
        self.beginByOwner = beginByOwner
        self.deltas = deltas
        self.endByOwner = endByOwner
        self.niTotal = niTotal
        self.winstSource = winstSource
        self.allocationNote = allocationNote
        self.openingTotal = openingTotal
        self.closingTotal = closingTotal
    }
}

// public struct PeriodRollforward: Sendable {
//     public let owners: [Int]
//     public let beginByOwner: [Int: Decimal]
//     public let deltas: [Int: OwnerDelta]
//     public let endByOwner: [Int: Decimal]
//     public let niTotal: Decimal
//     public let winstSource: WinstSource
//     public let allocationNote: [Int: (percent: Decimal, amount: Decimal)] // 0…1
//     public let openingTotal: Decimal
//     public let closingTotal: Decimal
    
//     public init(
//         owners: [Int],
//         beginByOwner: [Int: Decimal],
//         deltas: [Int: OwnerDelta],
//         endByOwner: [Int: Decimal],
//         niTotal: Decimal,
//         winstSource: WinstSource,
//         allocationNote: [Int: (percent: Decimal, amount: Decimal)], // 0…1,
//         openingTotal: Decimal,
//         closingTotal: Decimal
//     ) {
//         self.owners = owners
//         self.beginByOwner = beginByOwner
//         self.deltas = deltas
//         self.endByOwner = endByOwner
//         self.niTotal = niTotal
//         self.winstSource = winstSource
//         self.allocationNote = allocationNote
//         self.openingTotal = openingTotal
//         self.closingTotal = closingTotal
//     }
// }
