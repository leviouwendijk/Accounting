import Foundation

public struct StatementSection: Sendable {
    public let key: String
    public let title: String
    public let lines: [StatementLine]
    
    public init(
        key: String,
        title: String,
        lines: [StatementLine]
    ) {
        self.key = key
        self.title = title
        self.lines = lines
    }
}
