import Foundation

public struct VATAuditEntry: Sendable, Codable, Hashable {
    public let entryId: Int?
    public let postingDate: Date
    public let kind: VATKind
    public let period: VATPeriod

    /// Absolute VAT-relevant movement extracted from VAT accounts
    /// touched by this annotated entry.
    public let amount: Decimal

    public let vatAccountCodes: [String]
    public let details: String?

    public init(
        entryId: Int?,
        postingDate: Date,
        kind: VATKind,
        period: VATPeriod,
        amount: Decimal,
        vatAccountCodes: [String],
        details: String?
    ) {
        self.entryId = entryId
        self.postingDate = postingDate
        self.kind = kind
        self.period = period
        self.amount = amount
        self.vatAccountCodes = vatAccountCodes
        self.details = details
    }
}

public struct VATAuditQuarter: Sendable, Codable, Hashable {
    public let period: VATPeriod

    /// Quarter ledger picture based on resolved postings dated in the quarter.
    public let ledgerOwed: Decimal
    public let ledgerReceivable: Decimal
    public let ledgerNet: Decimal

    /// Explicit VAT-tagged events assigned to this VAT period.
    public let filed: Decimal
    public let paid: Decimal
    public let refunded: Decimal
    public let corrected: Decimal

    /// ledgerNet - (filed + corrected)
    public let ledgerVsDeclaredDelta: Decimal

    public let entries: [VATAuditEntry]

    public init(
        period: VATPeriod,
        ledgerOwed: Decimal,
        ledgerReceivable: Decimal,
        ledgerNet: Decimal,
        filed: Decimal,
        paid: Decimal,
        refunded: Decimal,
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
        self.refunded = refunded
        self.corrected = corrected
        self.ledgerVsDeclaredDelta = ledgerVsDeclaredDelta
        self.entries = entries
    }

    public var declaredTotal: Decimal {
        filed + corrected
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

    public var totalRefunded: Decimal {
        quarters.reduce(0) { $0 + $1.refunded }
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
}
