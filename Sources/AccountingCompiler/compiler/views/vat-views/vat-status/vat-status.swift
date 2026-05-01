import Accounting
import Foundation

public enum VATStatusFamily: String, Codable, Sendable, Hashable, CaseIterable {
    case output
    case deductible
    case privateUse
    case receivable
    case payableFallback

    public var displayLabel: String {
        switch self {
        case .output:
            return "output / 1a"

        case .deductible:
            return "deductible / 5b"

        case .privateUse:
            return "private use / 1d"

        case .receivable:
            return "receivable"

        case .payableFallback:
            return "payable fallback"
        }
    }
}

public struct VATStatusContribution: Sendable, Codable, Hashable {
    public let sourcePeriod: VATPeriod
    public let amount: Decimal

    public init(
        sourcePeriod: VATPeriod,
        amount: Decimal
    ) {
        self.sourcePeriod = sourcePeriod
        self.amount = amount
    }
}

public struct VATStatusTreeNode: Sendable, Codable, Hashable {
    public let id: Int
    public let code: String
    public let label: String
    public let amount: Decimal
    public let children: [VATStatusTreeNode]

    public init(
        id: Int,
        code: String,
        label: String,
        amount: Decimal,
        children: [VATStatusTreeNode]
    ) {
        self.id = id
        self.code = code
        self.label = label
        self.amount = amount
        self.children = children
    }
}

public struct VATStatusFamilyBreakdown: Sendable, Codable, Hashable {
    public let family: VATStatusFamily
    public let amount: Decimal
    public let nodes: [VATStatusTreeNode]

    public init(
        family: VATStatusFamily,
        amount: Decimal,
        nodes: [VATStatusTreeNode]
    ) {
        self.family = family
        self.amount = amount
        self.nodes = nodes
    }
}

public struct VATStatusFilingRow: Sendable, Codable, Hashable {
    public let family: VATStatusFamily
    public let carryIn: Decimal
    public let period: Decimal
    public let net: Decimal

    public init(
        family: VATStatusFamily,
        carryIn: Decimal,
        period: Decimal,
        net: Decimal
    ) {
        self.family = family
        self.carryIn = carryIn
        self.period = period
        self.net = net
    }
}

public struct VATStatusQuarter: Sendable, Codable, Hashable {
    public let period: VATPeriod

    /// Running open amount brought in from earlier quarters in the selected view.
    public let carryIn: Decimal

    /// Native account-polarity composition:
    /// debit = positive, credit = negative.
    public let outputNet: Decimal
    public let deductibleNet: Decimal
    public let privateUseNet: Decimal
    public let receivableNet: Decimal
    public let payableFallbackNet: Decimal

    /// Sum of the ordinary composition buckets.
    public let ordinaryNet: Decimal

    /// Per-family per-RGS-node tree for the ordinary composition.
    public let ordinaryBreakdownTree: [VATStatusFamilyBreakdown]

    /// Per-filing-family carry-in + period + net view.
    public let filingBreakdown: [VATStatusFilingRow]

    /// Signed semantic corrections assigned to this VAT quarter.
    public let correctionsNet: Decimal

    /// Amount that should be cleared for this quarter after carry-in and corrections.
    public let expectedSettlementNet: Decimal

    /// Semantic settlement display totals.
    public let paid: Decimal
    public let received: Decimal

    /// Native account-polarity settlement effect:
    /// debit settlement = positive, credit settlement = negative.
    public let settlementNet: Decimal

    /// Remaining open amount after settlement.
    /// Negative = owed (credit liability left open)
    /// Positive = receivable / debit residue left open
    public let residual: Decimal

    /// Compact breakdown of which source quarter(s) still contribute to the residual.
    public let residualContributions: [VATStatusContribution]

    /// Tagged administrative entries belonging to this quarter.
    public let entries: [VATAuditEntry]

    public init(
        period: VATPeriod,
        carryIn: Decimal,
        outputNet: Decimal,
        deductibleNet: Decimal,
        privateUseNet: Decimal,
        receivableNet: Decimal,
        payableFallbackNet: Decimal,
        ordinaryNet: Decimal,
        ordinaryBreakdownTree: [VATStatusFamilyBreakdown],
        filingBreakdown: [VATStatusFilingRow],
        correctionsNet: Decimal,
        expectedSettlementNet: Decimal,
        paid: Decimal,
        received: Decimal,
        settlementNet: Decimal,
        residual: Decimal,
        residualContributions: [VATStatusContribution],
        entries: [VATAuditEntry]
    ) {
        self.period = period
        self.carryIn = carryIn
        self.outputNet = outputNet
        self.deductibleNet = deductibleNet
        self.privateUseNet = privateUseNet
        self.receivableNet = receivableNet
        self.payableFallbackNet = payableFallbackNet
        self.ordinaryNet = ordinaryNet
        self.ordinaryBreakdownTree = ordinaryBreakdownTree
        self.filingBreakdown = filingBreakdown
        self.correctionsNet = correctionsNet
        self.expectedSettlementNet = expectedSettlementNet
        self.paid = paid
        self.received = received
        self.settlementNet = settlementNet
        self.residual = residual
        self.residualContributions = residualContributions
        self.entries = entries
    }

    public var displayResidualOwed: Decimal {
        residual < 0 ? (-residual) : 0
    }

    public var displayResidualReceivable: Decimal {
        residual > 0 ? residual : 0
    }

    public var isCleared: Bool {
        residual == 0
    }
}

public struct VATStatusReport: Sendable, Codable, SectionedPresentableOutput {
    public let title: String
    public let quarters: [VATStatusQuarter]
    public let tolerance: Decimal

    public init(
        title: String,
        quarters: [VATStatusQuarter],
        tolerance: Decimal
    ) {
        self.title = title
        self.quarters = quarters
        self.tolerance = tolerance
    }

    public var flaggedQuarters: [VATStatusQuarter] {
        quarters.filter {
            DecimalFuncs.absDec($0.residual) > tolerance
        }
    }

    public var latestResidual: Decimal {
        quarters.last?.residual ?? 0
    }

    public var latestDisplayResidualOwed: Decimal {
        latestResidual < 0 ? (-latestResidual) : 0
    }

    public var latestDisplayResidualReceivable: Decimal {
        latestResidual > 0 ? latestResidual : 0
    }
}
