import Foundation
import Primitives

/// Reporting positions advanced from an explicitly supplied checkpoint.
/// This does not accept, close, or route accounting periods.
public struct MovementPositions: Invariant, Sendable {
    public struct Raw: Sendable {
        public let checkpoint: PositionState
        public let slices: MovementSlices
        public let source: Provenance.Identifier
        public let lineages: [Provenance]

        public init(
            checkpoint: PositionState,
            slices: MovementSlices,
            source: Provenance.Identifier,
            lineages: [Provenance]
        ) {
            self.checkpoint = checkpoint
            self.slices = slices
            self.source = source
            self.lineages = lineages
        }
    }

    /// Strict construction path for a source-provider-attested ledger slice.
    public struct BoundedRaw: Sendable {
        public let checkpoint: PositionState
        public let selection: MovementSelection
        public let source: MovementSource
        public let lineages: [Provenance]

        public init(
            checkpoint: PositionState,
            selection: MovementSelection,
            source: MovementSource,
            lineages: [Provenance]
        ) {
            self.checkpoint = checkpoint
            self.selection = selection
            self.source = source
            self.lineages = lineages
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case uncoveredSelection
        case checkpointRevisionMismatch
        case missingSourceRevisionLineage(Int)
        case checkpointBoundaryMismatch
        case noncontiguousWindow(Int)
        case incompatibleChart
        case incompatibleEntities
        case lineageCountMismatch(expected: Int, actual: Int)
        case duplicateResultIdentifier(Int)
        case missingPrecedingLineage(Int)
        case missingSourceLineage(Int)
        case invalidResultState(index: Int, error: PositionState.Error)
    }

    public struct Window: Sendable {
        public let interval: MovementSelection.Window
        public let opening: PositionState
        public let movements: Balances
        public let result: PositionState

        fileprivate init(
            interval: MovementSelection.Window,
            opening: PositionState,
            movements: Balances,
            result: PositionState
        ) {
            self.interval = interval
            self.opening = opening
            self.movements = movements
            self.result = result
        }

        public struct Breakdown: Sendable {
            public let opening: Balances.Amount
            public let movements: Balances.Amount
            public let result: Balances.Amount
        }

        public func breakdown(
            for account: Account.Reference,
            entity: Entity.Reference? = nil
        ) -> Breakdown? {
            guard let opening = self.opening.amount(for: account, entity: entity),
                  let movements = self.movements.amount(for: account, entity: entity),
                  let result = self.result.amount(for: account, entity: entity)
            else {
                return nil
            }
            return Breakdown(opening: opening, movements: movements, result: result)
        }
    }

    private struct Key: Hashable, Sendable {
        let account: Account.Reference
        let entity: Entity.Reference
    }

    public let checkpoint: PositionState
    public let selection: MovementSelection
    public let source: Provenance.Identifier
    public let coverage: MovementSource.Coverage?
    public let windows: [Window]

    public init(_ raw: Raw) throws(Error) {
        try self.init(raw, coverage: nil)
    }

    public init(_ raw: BoundedRaw) throws(Error) {
        let coverage = raw.source.coverage
        guard coverage.contains(raw.selection) else {
            throw .uncoveredSelection
        }

        let revisionInput = Provenance.Input.sourceRevision(
            source: coverage.source,
            revision: coverage.revision
        )
        guard raw.checkpoint.provenance.inputs.contains(revisionInput) else {
            throw .checkpointRevisionMismatch
        }
        for (index, lineage) in raw.lineages.enumerated() {
            guard lineage.inputs.contains(revisionInput) else {
                throw .missingSourceRevisionLineage(index)
            }
        }

        let slices = MovementSlices(.init(
            ledger: raw.source.ledger,
            selection: raw.selection
        ))
        try self.init(Raw(
            checkpoint: raw.checkpoint,
            slices: slices,
            source: coverage.source,
            lineages: raw.lineages
        ), coverage: coverage)
    }

    private init(
        _ raw: Raw,
        coverage: MovementSource.Coverage?
    ) throws(Error) {
        let slices = raw.slices.windows
        let journal = raw.slices.recorded_before.ledger.journal

        guard raw.checkpoint.boundary == slices[0].interval.start else {
            throw .checkpointBoundaryMismatch
        }
        for index in 1..<slices.count {
            guard slices[index - 1].interval.end == slices[index].interval.start else {
                throw .noncontiguousWindow(index)
            }
        }
        guard raw.checkpoint.chart.isCompatibleForContinuity(with: journal.chart) else {
            throw .incompatibleChart
        }
        guard raw.checkpoint.entities.count == journal.entities.count else {
            throw .incompatibleEntities
        }
        for entity in raw.checkpoint.entities.all {
            guard let other = journal.entities.entity(entity.reference),
                  other.displayName == entity.displayName,
                  other.details == entity.details,
                  other.metadata == entity.metadata
            else {
                throw .incompatibleEntities
            }
        }
        guard raw.lineages.count == slices.count else {
            throw .lineageCountMismatch(
                expected: slices.count,
                actual: raw.lineages.count
            )
        }

        var prior = raw.checkpoint
        var seen: Set<Provenance.Identifier> = [prior.provenance.result]
        var windows: [Window] = []
        windows.reserveCapacity(slices.count)

        for (index, slice) in slices.enumerated() {
            let lineage = raw.lineages[index]
            guard seen.insert(lineage.result).inserted else {
                throw .duplicateResultIdentifier(index)
            }
            guard lineage.inputs.contains(.calculation(prior.provenance.result)) else {
                throw .missingPrecedingLineage(index)
            }
            guard lineage.inputs.contains(.source(raw.source)) else {
                throw .missingSourceLineage(index)
            }

            var cells = prior.cells
            var offsets: [Key: Int] = [:]
            for (cellIndex, cell) in cells.enumerated() {
                offsets[Key(account: cell.account, entity: cell.entity)] = cellIndex
            }

            for posting in slice.movements.postings {
                let key = Key(account: posting.account, entity: posting.entity)
                if let cellIndex = offsets[key] {
                    let cell = cells[cellIndex]
                    cells[cellIndex] = PositionState.Cell(
                        account: cell.account,
                        entity: cell.entity,
                        amount: cell.amount + posting.signedAmount
                    )
                } else {
                    offsets[key] = cells.count
                    cells.append(PositionState.Cell(
                        account: posting.account,
                        entity: posting.entity,
                        amount: posting.signedAmount
                    ))
                }
            }

            let next: PositionState
            do {
                next = try PositionState(.init(
                    chart: journal.chart,
                    entities: journal.entities,
                    boundary: slice.interval.end,
                    cells: cells,
                    provenance: lineage
                ))
            } catch {
                throw .invalidResultState(index: index, error: error)
            }
            windows.append(Window(
                interval: slice.interval,
                opening: prior,
                movements: slice.movements,
                result: next
            ))
            prior = next
        }

        self.checkpoint = raw.checkpoint
        self.selection = raw.slices.selection
        self.source = raw.source
        self.coverage = coverage
        self.windows = windows
    }

    public func window(for role: MovementSelection.Role) -> Window? {
        windows.first { $0.interval.role == role }
    }

    public var result: PositionState {
        windows[windows.count - 1].result
    }
}
