import Foundation

extension RGSAssembler {
    public static func present(
        _ amount: Decimal,
        direction: Direction,
        mode: OmslagMode = .apply
    ) -> Decimal {
        guard mode == .apply else { return amount }
        switch direction {
        case .debit:  return amount
        case .credit: return -amount
        }
    }
}
