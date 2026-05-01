import Foundation

public struct ECSyntaxFragment: Sendable {
    public let text: String
    public let kind: ECSyntaxKind

    public init(
        text: String,
        kind: ECSyntaxKind
    ) {
        self.text = text
        self.kind = kind
    }
}
