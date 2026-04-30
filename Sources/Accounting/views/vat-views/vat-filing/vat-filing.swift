import Foundation

public enum VATFilingFamily: String, Codable, Sendable, Hashable, CaseIterable {
    case output
    case deductible
    case privateUse
    case receivable
    case payableFallback
    case other
}

public struct VATFilingSourceRow: Codable, Sendable, Hashable {
    public let code: String
    public let label: String
    public let amount: Decimal
    public let entryIDs: [Int]

    public init(
        code: String,
        label: String,
        amount: Decimal,
        entryIDs: [Int]
    ) {
        self.code = code
        self.label = label
        self.amount = amount
        self.entryIDs = entryIDs
    }
}

public struct VATFilingVATRow: Codable, Sendable, Hashable {
    public let family: VATFilingFamily
    public let code: String
    public let label: String
    public let turnover: Decimal?
    public let vat: Decimal
    public let rawVAT: Decimal
    public let sourceRows: [VATFilingSourceRow]

    public init(
        family: VATFilingFamily,
        code: String,
        label: String,
        turnover: Decimal?,
        vat: Decimal,
        rawVAT: Decimal,
        sourceRows: [VATFilingSourceRow]
    ) {
        self.family = family
        self.code = code
        self.label = label
        self.turnover = turnover
        self.vat = vat
        self.rawVAT = rawVAT
        self.sourceRows = sourceRows
    }
}

public struct VATFilingCarryRow: Codable, Sendable, Hashable {
    public let sourcePeriod: VATPeriod
    public let entryId: Int?
    public let family: VATStatusFamily
    public let code: String
    public let label: String
    public let amount: Decimal
    public let isFileableRubricCarry: Bool
    public let isSettlementRemainder: Bool

    public init(
        sourcePeriod: VATPeriod,
        entryId: Int?,
        family: VATStatusFamily,
        code: String,
        label: String,
        amount: Decimal,
        isFileableRubricCarry: Bool,
        isSettlementRemainder: Bool
    ) {
        self.sourcePeriod = sourcePeriod
        self.entryId = entryId
        self.family = family
        self.code = code
        self.label = label
        self.amount = amount
        self.isFileableRubricCarry = isFileableRubricCarry
        self.isSettlementRemainder = isSettlementRemainder
    }
}

public struct VATFilingBalanceRow: Codable, Sendable, Hashable {
    public let family: VATFilingFamily
    public let code: String
    public let label: String
    public let turnover: Decimal?

    public let currentRaw: Decimal
    public let carryRaw: Decimal
    public let filingRaw: Decimal

    public let currentVAT: Decimal
    public let carryVAT: Decimal
    public let filingVAT: Decimal

    public init(
        family: VATFilingFamily,
        code: String,
        label: String,
        turnover: Decimal?,
        currentRaw: Decimal,
        carryRaw: Decimal,
        filingRaw: Decimal,
        currentVAT: Decimal,
        carryVAT: Decimal,
        filingVAT: Decimal
    ) {
        self.family = family
        self.code = code
        self.label = label
        self.turnover = turnover
        self.currentRaw = currentRaw
        self.carryRaw = carryRaw
        self.filingRaw = filingRaw
        self.currentVAT = currentVAT
        self.carryVAT = carryVAT
        self.filingVAT = filingVAT
    }
}

public struct VATFilingReconciliation: Codable, Sendable, Hashable {
    public let currentReturnRaw: Decimal
    public let currentPayable: Decimal
    public let currentReceivable: Decimal
    public let carryIn: Decimal
    public let expectedSettlementRaw: Decimal
    public let expectedPayable: Decimal
    public let expectedReceivable: Decimal
    public let balanceSheetNetPosition: Decimal?
    public let statusDifference: Decimal?
    public let includedVATRaw: Decimal
    public let allVATRootRaw: Decimal
    public let unclassifiedDifference: Decimal

    public init(
        currentReturnRaw: Decimal,
        currentPayable: Decimal,
        currentReceivable: Decimal,
        carryIn: Decimal,
        expectedSettlementRaw: Decimal,
        expectedPayable: Decimal,
        expectedReceivable: Decimal,
        balanceSheetNetPosition: Decimal?,
        statusDifference: Decimal?,
        includedVATRaw: Decimal,
        allVATRootRaw: Decimal,
        unclassifiedDifference: Decimal
    ) {
        self.currentReturnRaw = currentReturnRaw
        self.currentPayable = currentPayable
        self.currentReceivable = currentReceivable
        self.carryIn = carryIn
        self.expectedSettlementRaw = expectedSettlementRaw
        self.expectedPayable = expectedPayable
        self.expectedReceivable = expectedReceivable
        self.balanceSheetNetPosition = balanceSheetNetPosition
        self.statusDifference = statusDifference
        self.includedVATRaw = includedVATRaw
        self.allVATRootRaw = allVATRootRaw
        self.unclassifiedDifference = unclassifiedDifference
    }
}

public struct VATFilingReport: Codable, Sendable, SectionedPresentableOutput {
    public let title: String
    public let period: VATPeriod
    public let turnoverRows: [VATFilingSourceRow]
    public let vatRows: [VATFilingVATRow]
    public let otherVATRows: [VATFilingVATRow]
    public let carryRows: [VATFilingCarryRow]
    public let filingBalanceRows: [VATFilingBalanceRow]
    public let reconciliation: VATFilingReconciliation
    public let warnings: [String]

    public init(
        title: String,
        period: VATPeriod,
        turnoverRows: [VATFilingSourceRow],
        vatRows: [VATFilingVATRow],
        otherVATRows: [VATFilingVATRow],
        carryRows: [VATFilingCarryRow],
        filingBalanceRows: [VATFilingBalanceRow],
        reconciliation: VATFilingReconciliation,
        warnings: [String]
    ) {
        self.title = title
        self.period = period
        self.turnoverRows = turnoverRows
        self.vatRows = vatRows
        self.otherVATRows = otherVATRows
        self.carryRows = carryRows
        self.filingBalanceRows = filingBalanceRows
        self.reconciliation = reconciliation
        self.warnings = warnings
    }
}
