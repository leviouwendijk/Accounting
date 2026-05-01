import Accounting
import Foundation

// NEW ABSTRACTED SEED KERNEL MODELS

public struct AssemblerKernelSeedPlan: Sendable {
    public let incomeSeed: [Int: Decimal]
    public let balanceSeed: [Int: Decimal]
    public let balanceSeedAE: [AccEntKey: Decimal]?
    public let netIncomePresentationId: Int?
    public let netIncomePresentationCode: String?
    public let equityPresentationId: Int?
    public let equityPresentationCode: String?
    public let netIncomeOverlay: Decimal
    public let suppressOverlay: Bool

    public init(
        incomeSeed: [Int: Decimal],
        balanceSeed: [Int: Decimal],
        balanceSeedAE: [AccEntKey: Decimal]? = nil,
        netIncomePresentationId: Int? = nil,
        netIncomePresentationCode: String? = nil,
        equityPresentationId: Int? = nil,
        equityPresentationCode: String? = nil,
        netIncomeOverlay: Decimal = 0,
        suppressOverlay: Bool = false
    ) {
        self.incomeSeed = incomeSeed
        self.balanceSeed = balanceSeed
        self.balanceSeedAE = balanceSeedAE
        self.netIncomePresentationId = netIncomePresentationId
        self.netIncomePresentationCode = netIncomePresentationCode
        self.equityPresentationId = equityPresentationId
        self.equityPresentationCode = equityPresentationCode
        self.netIncomeOverlay = netIncomeOverlay
        self.suppressOverlay = suppressOverlay
    }
}

public struct AssemblerKernelSeedResult: Sendable {
    public let totalsIncome: [Int: Decimal]
    public let totalsBalance: [Int: Decimal]
    public let breakdown: EntityBreakdown?
    public let netIncome: Decimal
    public let effectiveCut: AssembleCut

    public init(
        totalsIncome: [Int: Decimal],
        totalsBalance: [Int: Decimal],
        breakdown: EntityBreakdown?,
        netIncome: Decimal,
        effectiveCut: AssembleCut
    ) {
        self.totalsIncome = totalsIncome
        self.totalsBalance = totalsBalance
        self.breakdown = breakdown
        self.netIncome = netIncome
        self.effectiveCut = effectiveCut
    }
}
