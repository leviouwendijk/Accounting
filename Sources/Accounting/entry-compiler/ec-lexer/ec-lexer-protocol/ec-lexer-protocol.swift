import Foundation

public enum EntryCompilerDetailsState: Sendable {
    case none, awaitingOpen, awaitingContent, awaitingClose
}

public protocol EntryCompilerLexing: Sendable {
    var scalars: [UnicodeScalar] { get }
    var index: Int { get set }
    var line: Int { get set }
    var column: Int { get set }
    var detailsState: EntryCompilerDetailsState { get set }

    mutating func nextToken() -> EntryCompilerToken
}
