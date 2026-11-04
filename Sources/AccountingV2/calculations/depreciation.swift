import Foundation

/// Expected depreciation, observed ledger activity and proposed corrections.
public enum Depreciation {
    public struct Schedule: Sendable {}
    public struct Reconciliation: Sendable {}
    public struct Proposal: Sendable {}
    public struct Audit: Sendable {}
}
