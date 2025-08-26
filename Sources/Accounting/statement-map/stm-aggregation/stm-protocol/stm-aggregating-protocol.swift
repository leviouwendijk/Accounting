import Foundation

public protocol StatementAggregating: Sendable {}

public typealias TraceHook = @Sendable (String, StatementCube) -> Void
