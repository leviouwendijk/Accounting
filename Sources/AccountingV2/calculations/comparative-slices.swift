import Foundation
import Primitives

/// V1-style comparative recorded views of one authoritative ledger.
/// Historical and previous views intentionally overlap. They are
/// independent projections, not additive accounting contributions.
/// Fiscal closing and ownership allocation are separate calculations.
public struct ComparativeSlices: Invariant, Sendable {
    public struct Raw: Sendable {
        public let ledger: Ledger
        public let selection: MovementSelection

        public init(ledger: Ledger, selection: MovementSelection) {
            self.ledger = ledger
            self.selection = selection
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case requiresTwoWindows
        case requiresPreviousAndCurrent
        case invalidComparisonOrder
    }

    public struct View: Sendable {
        public let interval: MovementSelection.Window
        public let recorded_opening: Balances
        public let movements: Balances
        public let recorded_position: Balances

        fileprivate init(
            interval: MovementSelection.Window,
            recorded_opening: Balances,
            movements: Balances,
            recorded_position: Balances
        ) {
            self.interval = interval
            self.recorded_opening = recorded_opening
            self.movements = movements
            self.recorded_position = recorded_position
        }
    }

    public let ledger: Ledger
    public let selection: MovementSelection

    /// Original postings before the previous comparison begins.
    public let historical_before_previous: Balances

    /// Original postings before the current comparison begins.
    /// Includes previous-period postings exactly once in this view.
    public let historical_before_current: Balances

    /// Recorded activity between previous.end and current.start.
    /// Empty for contiguous reporting windows.
    public let between: Balances

    public let previous: View
    public let current: View

    public init(_ raw: Raw) throws(Error) {
        guard raw.selection.windows.count == 2 else {
            throw .requiresTwoWindows
        }
        guard let previous = raw.selection.previous,
              let current = raw.selection.current else {
            throw .requiresPreviousAndCurrent
        }
        guard previous.end <= current.start else {
            throw .invalidComparisonOrder
        }

        var beforePrevious: [Int] = []
        var beforeCurrent: [Int] = []
        var previousMovements: [Int] = []
        var currentMovements: [Int] = []
        var previousPosition: [Int] = []
        var currentPosition: [Int] = []
        var between: [Int] = []

        // One membership traversal. Every offset still refers to the
        // original Ledger, including when several views refer to it.
        for (index, posting) in raw.ledger.postings.enumerated() {
            let date = posting.date

            if date < previous.start {
                beforePrevious.append(index)
            }
            if date < current.start {
                beforeCurrent.append(index)
            }
            if date < previous.end {
                previousPosition.append(index)
            }
            if date < current.end {
                currentPosition.append(index)
            }
            if date >= previous.start && date < previous.end {
                previousMovements.append(index)
            }
            if date >= previous.end && date < current.start {
                between.append(index)
            }
            if date >= current.start && date < current.end {
                currentMovements.append(index)
            }
        }

        let previousOpening = Balances(
            ledger: raw.ledger,
            selectedPostingOffsets: beforePrevious
        )
        let currentOpening = Balances(
            ledger: raw.ledger,
            selectedPostingOffsets: beforeCurrent
        )

        self.ledger = raw.ledger
        self.selection = raw.selection
        self.historical_before_previous = previousOpening
        self.historical_before_current = currentOpening
        self.between = Balances(
            ledger: raw.ledger,
            selectedPostingOffsets: between
        )
        self.previous = View(
            interval: previous,
            recorded_opening: previousOpening,
            movements: Balances(
                ledger: raw.ledger,
                selectedPostingOffsets: previousMovements
            ),
            recorded_position: Balances(
                ledger: raw.ledger,
                selectedPostingOffsets: previousPosition
            )
        )
        self.current = View(
            interval: current,
            recorded_opening: currentOpening,
            movements: Balances(
                ledger: raw.ledger,
                selectedPostingOffsets: currentMovements
            ),
            recorded_position: Balances(
                ledger: raw.ledger,
                selectedPostingOffsets: currentPosition
            )
        )
    }
}
