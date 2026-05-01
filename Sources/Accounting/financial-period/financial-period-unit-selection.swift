import Foundation

public struct FinancialPeriodUnitSelection: Sendable {
    public enum Basis: String, Sendable, Codable {
        case resolvedFiniteRange
        case unresolvedOpenRange
    }

    public let basis: Basis
    public let currentUnit: FinancialPeriodUnit?
    public let spanDays: Int?
    public let fittingUnits: [FinancialPeriodUnit]
    public let includedUnits: [FinancialPeriodUnit]
    public let excludedUnits: [FinancialPeriodUnit]

    public init(
        basis: Basis,
        currentUnit: FinancialPeriodUnit?,
        spanDays: Int?,
        fittingUnits: [FinancialPeriodUnit],
        includedUnits: [FinancialPeriodUnit],
        excludedUnits: [FinancialPeriodUnit]
    ) {
        self.basis = basis
        self.currentUnit = currentUnit
        self.spanDays = spanDays
        self.fittingUnits = fittingUnits
        self.includedUnits = includedUnits
        self.excludedUnits = excludedUnits
    }

    public var canCompareRealRange: Bool {
        basis == .resolvedFiniteRange
    }

    @inline(__always)
    public func includes(
        _ unit: FinancialPeriodUnit
    ) -> Bool {
        includedUnits.contains(unit)
    }

    @inline(__always)
    public func excludes(
        _ unit: FinancialPeriodUnit
    ) -> Bool {
        excludedUnits.contains(unit)
    }
}
