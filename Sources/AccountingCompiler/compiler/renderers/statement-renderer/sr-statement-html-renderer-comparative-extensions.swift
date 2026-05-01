import Accounting
import Foundation

extension StatementHTMLRenderer {
    @inline(__always)
    static func displayedComparativeAmount(
        rawAmount: Decimal,
        direction: Direction,
        orientation: AccountOrientation,
        sectionKind: TableSectionKind
    ) -> Decimal {
        switch sectionKind {
        case .incomeStatement:
            return displayedComparativeSignedAmount(
                rawAmount: rawAmount,
                direction: direction,
                orientation: orientation,
                normalDirection: .credit
            )

        case .balance(.other):
            return rawAmount

        case .balance(.assets):
            return displayedComparativeSignedAmount(
                rawAmount: rawAmount,
                direction: direction,
                orientation: orientation,
                normalDirection: .debit
            )

        case .balance(.equity), .balance(.liabilities):
            return displayedComparativeSignedAmount(
                rawAmount: rawAmount,
                direction: direction,
                orientation: orientation,
                normalDirection: .credit
            )
        }
    }

    @inline(__always)
    static func displayedComparativeSignedAmount(
        rawAmount: Decimal,
        direction: Direction,
        orientation: AccountOrientation,
        normalDirection: Direction
    ) -> Decimal {
        let magnitude = DecimalFuncs.absDec(rawAmount)

        let isPositive = (direction == normalDirection)
            == (orientation == .regular)

        return isPositive ? magnitude : -magnitude
    }
}
