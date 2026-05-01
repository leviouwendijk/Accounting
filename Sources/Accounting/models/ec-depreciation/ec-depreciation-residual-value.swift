import Foundation

public struct DepreciationResidualValue: Sendable, Codable {
    public var percent: Decimal
    private var acquisitionCost: AssetAcquisitionCost
    
    public init(
        percent: Decimal,
        acquisitionCost: AssetAcquisitionCost
    ) {
        self.percent = percent
        self.acquisitionCost = acquisitionCost
    }

    /// Accepts 0–1 or 0–100; returns 0–1.
    public var percentNormalized: Decimal {
        if percent < 0 {
            return 0
        }

        return percent > 1 ? (percent / 100) : percent
    }

    public var amount: Decimal {
        let raw = acquisitionCost.cost * percentNormalized
        return AccountingMoney.round(max(0, raw))
    }
}
// public struct DepreciationResidualValue: Sendable, Codable {
//     public var percent: Decimal
//     // public var amount: Decimal
//     private var acquisitionCost: AssetAcquisitionCost
    
//     public init(
//         percent: Decimal,
//         acquisitionCost: AssetAcquisitionCost
//     ) {
//         self.percent = percent
//         // self.amount = amount
//         self.acquisitionCost = acquisitionCost
//     }

//     /// Accepts 0–1 **or** 0–100; returns 0–1 
//     public var percentNormalized: Decimal {
//         if percent < 0 { return 0 }
//         return percent > 1 ? (percent / 100) : percent
//     }

//     public var amount: Decimal {
//         return max(0, acquisitionCost.cost * percentNormalized) 
//     }
// }
