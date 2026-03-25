import Foundation

public enum EntryCompilerDetailsState: Sendable {
    case none
    case awaitingOpen
    case awaitingContent
    case awaitingClose
}

public enum EntryCompilerReferenceState: Sendable {
    case none
    case awaitingEntityOpen
    case awaitingAccountOpen
    case entity
    case account
}

public protocol EntryCompilerLexing: Sendable {
    var scalars: [UnicodeScalar] { get }
    var index: Int { get set }
    var line: Int { get set }
    var column: Int { get set }
    var detailsState: EntryCompilerDetailsState { get set }
    var referenceState: EntryCompilerReferenceState { get set }

    mutating func nextToken() -> EntryCompilerToken
}
