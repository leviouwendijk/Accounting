import Foundation

public struct ChartMaps: Sendable {
    let idByCode: [String: Int]
    init(chart: CompiledChart) {
        idByCode = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.codes.code, $0.id) })
    }
}
