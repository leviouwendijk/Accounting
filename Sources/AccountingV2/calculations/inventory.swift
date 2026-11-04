import Foundation

/// Inventory quantity movements, valuation and reconciliation.
public enum Inventory {
    public struct Movement: Sendable {}
    public struct Valuation: Sendable {}
    public struct Position: Sendable {}
    public struct Reconciliation: Sendable {}
}
