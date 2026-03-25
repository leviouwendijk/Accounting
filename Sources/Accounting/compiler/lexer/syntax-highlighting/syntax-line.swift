import Foundation

public struct ECSyntaxLine: Sendable {
    public let number: Int
    public let fragments: [ECSyntaxFragment]

    public init(
        number: Int,
        fragments: [ECSyntaxFragment]
    ) {
        self.number = number
        self.fragments = fragments
    }

    public var text: String {
        fragments.map(\.text).joined()
    }
}
