import Foundation
import Primitives

public enum EntryHistoryEventKind: String, Hashable, Codable, Sendable, StringParsableEnum {
    case recorded
    case corrected
    case adjusted
}

public struct EntryHistoryEvent: Hashable, Codable, Sendable {
    public var kind: EntryHistoryEventKind
    public var date: DateSpecification
    public var details: String?
    public var location: SourceLocation?

    public init(
        kind: EntryHistoryEventKind,
        date: DateSpecification,
        details: String? = nil,
        location: SourceLocation? = nil
    ) {
        self.kind = kind
        self.date = date
        self.details = details
        self.location = location
    }
}

public struct EntryHistory: Hashable, Codable, Sendable {
    public var events: [EntryHistoryEvent]

    public init(
        events: [EntryHistoryEvent] = []
    ) {
        self.events = events
    }
}
