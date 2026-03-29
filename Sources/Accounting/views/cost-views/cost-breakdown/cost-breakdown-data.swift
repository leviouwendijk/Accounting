import Foundation

public enum CostViews {}

public enum CostBreakdownBucketKey: String, Sendable, CaseIterable {
    case autoEnTransport
    case huisvestingskosten
    case onderhoudOverigeMaterieleVasteActiva
    case verkoopkosten
    case andereKosten

    public var label: String {
        switch self {
        case .autoEnTransport:
            return "Auto- en transportkosten"

        case .huisvestingskosten:
            return "Huisvestingskosten"

        case .onderhoudOverigeMaterieleVasteActiva:
            return "Onderhoudskosten van overige materiële vaste activa"

        case .verkoopkosten:
            return "Verkoopkosten"

        case .andereKosten:
            return "Andere kosten"
        }
    }

    public var sortOrder: Int {
        switch self {
        case .autoEnTransport:
            return 10

        case .huisvestingskosten:
            return 20

        case .onderhoudOverigeMaterieleVasteActiva:
            return 30

        case .verkoopkosten:
            return 40

        case .andereKosten:
            return 50
        }
    }
}

public struct CostBreakdownBucketMember: Sendable {
    public let code: String
    public let label: String
    public let amount: Decimal

    public init(
        code: String,
        label: String,
        amount: Decimal
    ) {
        self.code = code
        self.label = label
        self.amount = amount
    }
}

public struct CostBreakdownBucket: Sendable {
    public let key: CostBreakdownBucketKey
    public let amount: Decimal
    public let matchedCodes: [String]
    public let members: [CostBreakdownBucketMember]

    public init(
        key: CostBreakdownBucketKey,
        amount: Decimal,
        matchedCodes: [String],
        members: [CostBreakdownBucketMember]
    ) {
        self.key = key
        self.amount = amount
        self.matchedCodes = matchedCodes
        self.members = members
    }

    public var label: String {
        key.label
    }
}

public struct CostBreakdownReconciliation: Sendable {
    public let sourceCode: String
    public let sourceLabel: String
    public let sourceTotal: Decimal

    public let childRootTotal: Decimal
    public let childRootDifference: Decimal

    public let bucketTotal: Decimal
    public let difference: Decimal

    public let otherResidual: Decimal
    public let otherChildrenTotal: Decimal
    public let otherDifference: Decimal

    public let tolerance: Decimal
    public let passed: Bool

    public init(
        sourceCode: String,
        sourceLabel: String,
        sourceTotal: Decimal,
        childRootTotal: Decimal,
        childRootDifference: Decimal,
        bucketTotal: Decimal,
        difference: Decimal,
        otherResidual: Decimal,
        otherChildrenTotal: Decimal,
        otherDifference: Decimal,
        tolerance: Decimal,
        passed: Bool
    ) {
        self.sourceCode = sourceCode
        self.sourceLabel = sourceLabel
        self.sourceTotal = sourceTotal
        self.childRootTotal = childRootTotal
        self.childRootDifference = childRootDifference
        self.bucketTotal = bucketTotal
        self.difference = difference
        self.otherResidual = otherResidual
        self.otherChildrenTotal = otherChildrenTotal
        self.otherDifference = otherDifference
        self.tolerance = tolerance
        self.passed = passed
    }
}

public struct CostBreakdownReport: PresentableOutput {
    public let title: String
    public let period: PeriodWindow
    public let buckets: [CostBreakdownBucket]
    public let reconciliation: CostBreakdownReconciliation

    public init(
        title: String,
        period: PeriodWindow,
        buckets: [CostBreakdownBucket],
        reconciliation: CostBreakdownReconciliation
    ) {
        self.title = title
        self.period = period
        self.buckets = buckets
        self.reconciliation = reconciliation
    }

    public var total: Decimal {
        buckets.reduce(0) { partial, bucket in
            partial + bucket.amount
        }
    }
}

public enum CostBreakdownError: LocalizedError, Sendable {
    case missingCode(String)
    case codeOutsideScope(code: String, scope: String)
    case reconciliationFailed(
        sourceCode: String,
        difference: Decimal,
        childRootDifference: Decimal,
        otherDifference: Decimal,
        tolerance: Decimal
    )

    public var errorDescription: String? {
        switch self {
        case .missingCode(let code):
            return "Cost breakdown: missing required RGS code '\(code)'."

        case .codeOutsideScope(let code, let scope):
            return "Cost breakdown: code '\(code)' is not an immediate child of '\(scope)'."

        case .reconciliationFailed(
            let sourceCode,
            let difference,
            let childRootDifference,
            let otherDifference,
            let tolerance
        ):
            return """
            Cost breakdown reconciliation failed for \(sourceCode).
            root-vs-buckets diff: \(difference)
            root-vs-direct-children diff: \(childRootDifference)
            residual-vs-other-children diff: \(otherDifference)
            tolerance: \(tolerance)
            """
        }
    }
}
