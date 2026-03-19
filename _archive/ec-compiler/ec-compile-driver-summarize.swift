// depends on archived StatementCube
public func summarize(_ name: String, cube: StatementCube) -> String {
    // total amount (period 0), number of partitions, number of rows matched
    let p0 = cube.filter { $0.key.periodIndex == 0 }
    let total = p0.reduce(Decimal(0)) { $0 + $1.value }
    let partitions = Set(p0.map { $0.key.partition })
    let rows = Set(p0.map { $0.key.row })
    return "  • \(name): rows=\(rows.count), partitions=\(partitions.count), total=\(total)"
}
