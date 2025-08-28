import Foundation

public struct AggregationPlan: Codable, Sendable {
    public let statement: StatementDef
    public let partition: PartitionSpec?          // e.g., keys:[.entity], requireBalanced:true for B/S
    public let filters: [DimensionFilter]         // e.g., entityClass IN ["objects"]
    public let includePreviousPeriods: Bool       // you already keep this in settings :contentReference[oaicite:7]{index=7}
    
    public init(
        statement: StatementDef,
        partition: PartitionSpec?,          // e.g., keys:[.entity], requireBalanced:true for B/S,
        filters: [DimensionFilter],         // e.g., entityClass IN ["objects"],
        includePreviousPeriods: Bool       // you already keep this in settings :contentReference[oaicite:7]{index=7}
    ) {
        self.statement = statement
        self.partition = partition
        self.filters = filters
        self.includePreviousPeriods = includePreviousPeriods
    }
}
