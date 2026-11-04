import Foundation
import Primitives

/// Immutable definitions indexed by full identity. Partial and wildcard resolution
/// belong to a separate, explicit policy introduced in a later pass.
public struct Entities: Invariant, Sendable {
    public typealias Raw = [Entity]

    public enum Error: Swift.Error, Equatable, Sendable {
        case duplicateReference(Entity.Reference)
        case unknownReference(Entity.Reference)
    }

    public let all: [Entity]
    private let byReference: [Entity.Reference: Entity]

    public init(_ raw: Raw) throws(Error) {
        var index: [Entity.Reference: Entity] = [:]
        index.reserveCapacity(raw.count)

        for entity in raw {
            guard index.updateValue(entity, forKey: entity.reference) == nil else {
                throw .duplicateReference(entity.reference)
            }
        }

        self.all = raw
        self.byReference = index
    }

    public var count: Int {
        all.count
    }

    public func entity(_ reference: Entity.Reference) -> Entity? {
        byReference[reference]
    }

    public func resolve(_ reference: Entity.Reference) throws(Error) -> Entity {
        guard let entity = byReference[reference] else {
            throw .unknownReference(reference)
        }
        return entity
    }
}

/// Effective-dated ownership relationships are separate from entity identity.
public enum Ownership {}
