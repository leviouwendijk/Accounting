import Foundation

extension TaxonomyProber {
    public static func loadCompiledChart(
        from chartFile: String
    ) throws -> CompiledChart {
        let chartURL = try TaxonomyShared.urlFromStringOrPath(chartFile)
        let data = try Data(contentsOf: chartURL)

        let decoder = JSONDecoder()
        return try decoder.decode(
            CompiledChart.self,
            from: data
        )
    }
}
