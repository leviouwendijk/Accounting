// import Foundation

// public struct StatementRow: Codable, Sendable {
//     public let code: String
//     public let label: String
//     public let amount: Decimal
//     public let level: Int
//     public let section: String
//     public let parentCode: String?
//     public let isTotal: Bool

//     public init(
//         code: String,
//         label: String,
//         amount: Decimal,
//         level: Int,
//         section: String,
//         parentCode: String? = nil,
//         isTotal: Bool = false
//     ) {
//         self.code = code
//         self.label = label
//         self.amount = amount
//         self.level = level
//         self.section = section
//         self.parentCode = parentCode
//         self.isTotal = isTotal
//     }
// }

// public struct FinancialRatio: Sendable {
//     public let name: String
//     public let value: Decimal
//     public let inputs: [String] // e.g. RGS L2 codes used (so we can recompute)
    
//     public init(
//         name: String,
//         value: Decimal,
//         inputs: [String] // e.g. RGS L2 codes used (so we can recompute)
//     ) {
//         self.name = name
//         self.value = value
//         self.inputs = inputs
//     }
// }
