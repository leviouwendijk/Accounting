import Foundation
import Primitives

/// Partitioned original ledger movements for a validated date selection.
/// One source traversal assigns posting offsets to disjoint windows.
/// Each Balances projection aggregates only its assigned original offsets.
public struct MovementSlices: Invariant, Sendable {
    public struct Raw: Sendable {
        public let ledger: Ledger
        public let selection: MovementSelection

        public init(ledger: Ledger, selection: MovementSelection) {
            self.ledger = ledger
            self.selection = selection
        }
    }

    public struct Window: Sendable {
        public let interval: MovementSelection.Window
        public let movements: Balances

        fileprivate init(
            interval: MovementSelection.Window,
            movements: Balances
        ) {
            self.interval = interval
            self.movements = movements
        }
    }

    public typealias Error = Never

    public let selection: MovementSelection

    /// Unadjusted recorded postings before the earliest selected window.
    /// This is not an accepted or fiscally closed PositionState.
    public let recorded_before: Balances

    /// Window movements ordered chronologically.
    /// Original journal order is retained within each window.
    public let windows: [Window]

    public init(_ raw: Raw) {
        let intervals = raw.selection.windows
        let earliest = intervals[0].start
        var before: [Int] = []
        var offsets = [[Int]](repeating: [], count: intervals.count)

        for (offset, posting) in raw.ledger.postings.enumerated() {
            if posting.date < earliest {
                before.append(offset)
                continue
            }

            // Binary search by exclusive window end, independent of journal
            // ordering. Gaps and future postings are intentionally excluded.
            var lower = 0
            var upper = intervals.count
            while lower < upper {
                let middle = lower + (upper - lower) / 2
                if posting.date >= intervals[middle].end {
                    lower = middle + 1
                } else {
                    upper = middle
                }
            }
            if lower < intervals.count,
               posting.date >= intervals[lower].start {
                offsets[lower].append(offset)
            }
        }

        self.selection = raw.selection
        self.recorded_before = Balances(
            ledger: raw.ledger,
            selectedPostingOffsets: before
        )
        self.windows = intervals.enumerated().map { index, interval in
            Window(
                interval: interval,
                movements: Balances(
                    ledger: raw.ledger,
                    selectedPostingOffsets: offsets[index]
                )
            )
        }
    }

    public func window(for role: MovementSelection.Role) -> Window? {
        windows.first { $0.interval.role == role }
    }
}
