import Foundation

public struct Plans {
    public static func make(
        _ type: StatementKind,
        partition: PartitionSpec? = nil,
        filters: [DimensionFilter] = [],
        includePrevious: Bool = false,
        materiality: Decimal = 0
    ) -> AggregationPlan {
        let def: StatementDef
        switch type {
        case .balance: def = StatementLibrary.balanceIFRS(materiality: materiality)
        case .income:  def = StatementLibrary.incomeStatementIFRS(materiality: materiality)
        case .cash:    def = StatementLibrary.cashSimple(materiality: materiality)
        case .equity:  def = StatementLibrary.equityView(materiality: materiality)
        }
        return AggregationPlan(statement: def, partition: partition, filters: filters, includePreviousPeriods: includePrevious)
    }
}
