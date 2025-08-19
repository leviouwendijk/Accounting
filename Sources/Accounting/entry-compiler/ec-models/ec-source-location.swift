import Foundation

public struct SourceLocation: CustomStringConvertible, Sendable {
    public let line: Int
    public let column: Int
    public var description: String { "\(line):\(column)" }
}
