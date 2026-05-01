import Accounting
public protocol PresentableInput: Sendable {}
public protocol PresentableOutput: Sendable {}

public protocol Presentation: Sendable {
    associatedtype Input: PresentableInput
    associatedtype Output: PresentableOutput

    static var id: String { get }
    static var title: String { get }

    func build(from input: Input) throws -> Output
}

extension Presentation {
    public var id: String { Self.id }
    public var title: String { Self.title }
}
