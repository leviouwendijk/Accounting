import Accounting
import Foundation

public struct VATAuditEntry: Sendable, Codable, Hashable {
    public let entryId: Int?
    public let postingDate: Date
    public let kind: VATKind
    public let settlementFlow: VATSettlementFlow?
    public let period: VATPeriod

    /// Signed VAT-relevant movement extracted from VAT accounts
    /// touched by this annotated entry.
    public let netAmount: Decimal

    /// Absolute display amount.
    public let amount: Decimal

    public let vatAccountCodes: [String]
    public let details: String?

    public init(
        entryId: Int?,
        postingDate: Date,
        kind: VATKind,
        settlementFlow: VATSettlementFlow? = nil,
        period: VATPeriod,
        netAmount: Decimal,
        amount: Decimal,
        vatAccountCodes: [String],
        details: String?
    ) {
        self.entryId = entryId
        self.postingDate = postingDate
        self.kind = kind
        self.settlementFlow = settlementFlow
        self.period = period
        self.netAmount = netAmount
        self.amount = amount
        self.vatAccountCodes = vatAccountCodes
        self.details = details
    }

    public var displayKind: String {
        switch kind {
        case .settlement:
            switch settlementFlow {
            case .paid?:
                return "settlement paid"
            case .received?:
                return "settlement received"
            case nil:
                return "settlement"
            }

        case .filing:
            return "filing"

        case .correction:
            return "correction"
        }
    }
}

public struct VATAuditQuarter: Sendable, Codable, Hashable {
    public let period: VATPeriod

    /// Raw buckets from VAT-account family matching.
    public let ledgerOwed: Decimal
    public let ledgerReceivable: Decimal
    public let ledgerNet: Decimal

    public let filed: Decimal
    public let paid: Decimal
    public let received: Decimal
    public let corrected: Decimal

    public let ledgerVsDeclaredDelta: Decimal

    public let entries: [VATAuditEntry]

    public init(
        period: VATPeriod,
        ledgerOwed: Decimal,
        ledgerReceivable: Decimal,
        ledgerNet: Decimal,
        filed: Decimal,
        paid: Decimal,
        received: Decimal,
        corrected: Decimal,
        ledgerVsDeclaredDelta: Decimal,
        entries: [VATAuditEntry]
    ) {
        self.period = period
        self.ledgerOwed = ledgerOwed
        self.ledgerReceivable = ledgerReceivable
        self.ledgerNet = ledgerNet
        self.filed = filed
        self.paid = paid
        self.received = received
        self.corrected = corrected
        self.ledgerVsDeclaredDelta = ledgerVsDeclaredDelta
        self.entries = entries
    }

    public var declaredTotal: Decimal {
        filed + corrected
    }

    /// User-facing economic position.
    public var displayLedgerOwed: Decimal {
        ledgerNet > 0 ? ledgerNet : 0
    }

    /// User-facing economic position.
    public var displayLedgerReceivable: Decimal {
        ledgerNet < 0 ? (-ledgerNet) : 0
    }
}

public struct VATAuditReport: Sendable, Codable, SectionedPresentableOutput {
    public let title: String
    public let quarters: [VATAuditQuarter]
    public let tolerance: Decimal

    public init(
        title: String,
        quarters: [VATAuditQuarter],
        tolerance: Decimal
    ) {
        self.title = title
        self.quarters = quarters
        self.tolerance = tolerance
    }

    public var totalLedgerOwed: Decimal {
        quarters.reduce(0) { $0 + $1.ledgerOwed }
    }

    public var totalLedgerReceivable: Decimal {
        quarters.reduce(0) { $0 + $1.ledgerReceivable }
    }

    public var totalLedgerNet: Decimal {
        quarters.reduce(0) { $0 + $1.ledgerNet }
    }

    public var totalFiled: Decimal {
        quarters.reduce(0) { $0 + $1.filed }
    }

    public var totalPaid: Decimal {
        quarters.reduce(0) { $0 + $1.paid }
    }

    public var totalReceived: Decimal {
        quarters.reduce(0) { $0 + $1.received }
    }

    public var totalCorrected: Decimal {
        quarters.reduce(0) { $0 + $1.corrected }
    }

    public var totalLedgerVsDeclaredDelta: Decimal {
        quarters.reduce(0) { $0 + $1.ledgerVsDeclaredDelta }
    }

    public var flaggedQuarters: [VATAuditQuarter] {
        quarters.filter {
            DecimalFuncs.absDec($0.ledgerVsDeclaredDelta) > tolerance
        }
    }

    /// User-facing economic position.
    public var displayTotalLedgerOwed: Decimal {
        totalLedgerNet > 0 ? totalLedgerNet : 0
    }

    /// User-facing economic position.
    public var displayTotalLedgerReceivable: Decimal {
        totalLedgerNet < 0 ? (-totalLedgerNet) : 0
    }
}
