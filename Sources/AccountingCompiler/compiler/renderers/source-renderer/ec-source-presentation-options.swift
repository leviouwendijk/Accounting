import Accounting
import Foundation

public struct ECSourcePresentationOptions: Sendable {
    public var title: String
    public var subtitle: String?
    public var showLineNumbers: Bool
    public var compact: Bool
    public var includeFileBlockCounts: Bool
    public var syntaxHighlighting: Bool

    public init(
        title: String = "EC Source",
        subtitle: String? = nil,
        showLineNumbers: Bool = true,
        compact: Bool = true,
        includeFileBlockCounts: Bool = true,
        syntaxHighlighting: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showLineNumbers = showLineNumbers
        self.compact = compact
        self.includeFileBlockCounts = includeFileBlockCounts
        self.syntaxHighlighting = syntaxHighlighting
    }
}
