public enum VATKind: String, Codable, Sendable, Hashable {
    case filing
    case payment
    case refund
    case correction
}

public enum VATQuarter: UInt8, Codable, Sendable, Hashable {
    case q1 = 1
    case q2 = 2
    case q3 = 3
    case q4 = 4
}

public struct VATPeriod: Codable, Sendable, Hashable {
    public let year: Int
    public let quarter: VATQuarter

    public init(
        year: Int,
        quarter: VATQuarter
    ) {
        self.year = year
        self.quarter = quarter
    }
}

public struct VATAnnotation: Codable, Sendable, Hashable {
    public let kind: VATKind
    public let period: VATPeriod

    public init(
        kind: VATKind,
        period: VATPeriod
    ) {
        self.kind = kind
        self.period = period
    }
}
