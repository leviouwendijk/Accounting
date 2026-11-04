import Foundation
import Primitives

/// Retained lineage of an accounting result.
/// References distinguish authoritative sources from derived calculations.
/// Identifiers are supplied by the producing layer; this type does not
/// generate hashes, authenticate references, or resolve their targets.
public struct Provenance: Sendable, Equatable {
    public struct Identifier: Invariant, Hashable, Sendable {
        public enum Error: Swift.Error, Equatable, Sendable {
            case empty
        }

        public let rawValue: String

        public init(_ raw: String) throws(Error) {
            guard !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw .empty
            }
            self.rawValue = raw
        }
    }

    /// A reference to an accepted source or an earlier calculation result.
    /// Keeping these cases distinct prevents treating derived values as facts.
    public enum Input: Hashable, Sendable {
        case source(Identifier)
        case sourceRevision(source: Identifier, revision: Identifier)
        case calculation(Identifier)
    }

    /// The configuration or policy that influenced this result.
    /// Revision identity must be provided by the owning policy implementation.
    public struct Policy: Hashable, Sendable {
        public let identifier: Identifier
        public let revision: Identifier

        public init(identifier: Identifier, revision: Identifier) {
            self.identifier = identifier
            self.revision = revision
        }
    }

    /// Identity of the result to which this lineage belongs.
    public let result: Identifier

    /// Direct dependencies, retained in declared order.
    /// The same authoritative source may support multiple calculation results.
    public let inputs: [Input]

    /// Optional when the result is independent of a configurable policy.
    public let policy: Policy?

    public init(
        result: Identifier,
        inputs: [Input],
        policy: Policy? = nil
    ) {
        self.result = result
        self.inputs = inputs
        self.policy = policy
    }
}

/// Opt-in contract for outputs that expose retained calculation lineage.
/// Do not require every Calculation.Output to conform prematurely.
public protocol ProvenanceProviding: Sendable {
    var provenance: Provenance { get }
}

/// Explicit request to create or change source accounting data.
/// A proposal is not a recorded journal entry.
public struct MutationProposal: Sendable {}
