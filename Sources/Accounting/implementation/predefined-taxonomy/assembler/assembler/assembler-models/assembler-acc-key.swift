import Foundation

public struct AccEntKey: Hashable, Sendable {
    public let accountId: Int
    public let entityId: Int?   // nil = unassigned

    @inlinable 
    public init(_ a: Int, _ e: Int?) { self.accountId = a; self.entityId = e }
}

