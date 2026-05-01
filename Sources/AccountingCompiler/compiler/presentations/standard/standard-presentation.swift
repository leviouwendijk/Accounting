import Accounting
public struct StandardPresentation: Presentation {
    public typealias Input = BundlePresentationInput
    public typealias Output = StatementBundle

    public static let id = "standard"
    public static let title = "Standard statement"

    public init() {}

    public func build(from input: Input) throws -> Output {
        input.bundle
    }
}
