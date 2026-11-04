import Foundation
import Primitives

/// A bounded journal supplied under an explicit source coverage claim.
/// The source adapter is responsible for asserting completeness. This
/// value validates the claimed interval and every entry received, but
/// cannot independently detect omitted entries or authenticate revisions.
public struct MovementSource: Invariant, Sendable {
    public struct Raw: Sendable {
        public let ledger: Ledger
        public let source: Provenance.Identifier
        public let revision: Provenance.Identifier
        public let start: Date
        public let end: Date

        public init(
            ledger: Ledger,
            source: Provenance.Identifier,
            revision: Provenance.Identifier,
            start: Date,
            end: Date
        ) {
            self.ledger = ledger
            self.source = source
            self.revision = revision
            self.start = start
            self.end = end
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidStart
        case invalidEnd
        case invalidRange
        case entryOutsideCoverage(Entry.ID)
    }

    public struct Coverage: Sendable {
        public let source: Provenance.Identifier
        public let revision: Provenance.Identifier
        public let start: Date
        public let end: Date

        fileprivate init(
            source: Provenance.Identifier,
            revision: Provenance.Identifier,
            start: Date,
            end: Date
        ) {
            self.source = source
            self.revision = revision
            self.start = start
            self.end = end
        }

        public func contains(_ selection: MovementSelection) -> Bool {
            guard let first = selection.windows.first,
                  let last = selection.windows.last else {
                return false
            }
            return start <= first.start && last.end <= end
        }
    }

    public let ledger: Ledger
    public let coverage: Coverage

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

        for entry in raw.ledger.journal.entries {
            guard entry.date >= raw.start && entry.date < raw.end else {
                throw .entryOutsideCoverage(entry.id)
            }
        }

        self.ledger = raw.ledger
        self.coverage = Coverage(
            source: raw.source,
            revision: raw.revision,
            start: raw.start,
            end: raw.end
        )
    }
}