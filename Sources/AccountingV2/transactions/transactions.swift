import Foundation
import Primitives

/// Independently recorded financial transaction.
public struct Transaction: Sendable {
    public struct ID: Sendable {}
}

/// Collection boundary for transaction identities and consistency.
public struct Transactions: Sendable {}
