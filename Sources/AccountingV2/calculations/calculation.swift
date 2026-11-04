import Foundation

/// One typed, deterministic accounting calculation boundary.
/// Implementations retain their own configuration and domain policies.
/// Outputs remain domain-specific; they are not required to share a result shape.
public protocol Calculation: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Sendable

    func evaluate(_ input: Input) throws -> Output
}
