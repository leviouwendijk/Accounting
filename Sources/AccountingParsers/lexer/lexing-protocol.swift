import Foundation
import Accounting

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

    var lastConsumedLine: Int { get set }
    var lastConsumedColumn: Int { get set }

    var detailsState: EntryCompilerDetailsState { get set }
    var referenceState: EntryCompilerReferenceState { get set }

    var diagnostics: [EntryCompilerLexDiagnostic] { get set }
    var lastTokenSpan: SourceSpan? { get set }

    mutating func nextToken() -> EntryCompilerToken
}
