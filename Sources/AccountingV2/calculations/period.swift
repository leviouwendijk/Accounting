import Foundation
import Primitives

/// Time-bounded, immutable interpretation of an authoritative Ledger.
///
/// Time intervals are half-open: [start, end).
/// Opening includes earlier postings, movements includes interval postings,
/// and position includes all postings before the exclusive end.
///
/// These are unadjusted signed ledger positions. Closing, temporary-account
/// treatment and statement normalization are separate calculations.
public struct Period: Invariant, Sendable {
    public struct Raw: Sendable {
        public let ledger: Ledger
        public let start: Date
        public let end: Date

        public init(ledger: Ledger, start: Date, end: Date) {
            self.ledger = ledger
            self.start = start
            self.end = end
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidStart
        case invalidEnd
        case invalidRange
    }

    public let ledger: Ledger
    public let start: Date
    public let end: Date

    /// All original posting contributions before the period starts.
    public let opening: Balances

    /// Original posting contributions within the requested period.
    public let movements: Balances

    /// All original posting contributions before the period ends.
    /// For any account, position = opening + movements.
    public let position: Balances

    public init(_ raw: Raw) throws(Error) {
        guard raw.start.timeIntervalSinceReferenceDate.isFinite else {
            throw .invalidStart
        }
        guard raw.end.timeIntervalSinceReferenceDate.isFinite else {
            throw .invalidEnd
        }
        guard raw.start < raw.end else {
            throw .invalidRange
        }

        self.ledger = raw.ledger
        self.start = raw.start
        self.end = raw.end
        self.opening = Balances(ledger: raw.ledger, including: {
            $0.date < raw.start
        })
        self.movements = Balances(ledger: raw.ledger, including: {
            $0.date >= raw.start && $0.date < raw.end
        })
        self.position = Balances(ledger: raw.ledger, including: {
            $0.date < raw.end
        })
    }
}
