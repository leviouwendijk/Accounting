public protocol BundlePresentableInput: PresentableInput {
    var chart: CompiledChart { get }
    var bundle: StatementBundle { get }
    var entities: EntityStore? { get }
}

public protocol HistoryPresentableInput: PresentableInput {
    var chart: CompiledChart { get }
    var entities: EntityStore { get }
}

public protocol SectionedPresentableOutput: PresentableOutput {
    var title: String { get }
}
