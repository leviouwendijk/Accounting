import Foundation

public struct IdentifiableByYQM: Hashable, Sendable {
    public let id: Int
    public let yqm: YQM
    
    public init(
        id: Int,
        yqm: YQM
    ) {
        self.id = id
        self.yqm = yqm
    }
}

public struct PlannedMonthlyTypeFile: Sendable {
    public let yqm: YQM
    public let type: LegacyJournalEntryType
    public let relativePath: String
    public let ids: [Int]
    
    public init(
        yqm: YQM,
        type: LegacyJournalEntryType,
        relativePath: String,
        ids: [Int]
    ) {
        self.yqm = yqm
        self.type = type
        self.relativePath = relativePath
        self.ids = ids
    }

    public var count: Int { ids.count }
}

public struct LegacyYQMSummary: Sendable, Codable {
    public let counts: [Int: [Int: [Int: Int]]] // year → quarter → month → count
}
