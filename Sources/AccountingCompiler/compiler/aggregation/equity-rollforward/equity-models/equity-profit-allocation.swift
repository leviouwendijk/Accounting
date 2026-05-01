import Accounting
import Foundation

public struct ProfitAllocation: Sendable {
    public let niTotal: Decimal
    public let usePosted: Bool
    public let usedAmounts: [Int: Decimal]        // per owner
    public let effectivePercents: [Int: Decimal]  // 0…1
    public let source: WinstSource
    public init(niTotal: Decimal, usePosted: Bool, usedAmounts: [Int: Decimal], effectivePercents: [Int: Decimal], source: WinstSource) {
        self.niTotal = niTotal; self.usePosted = usePosted; self.usedAmounts = usedAmounts; self.effectivePercents = effectivePercents; self.source = source
    }
}

