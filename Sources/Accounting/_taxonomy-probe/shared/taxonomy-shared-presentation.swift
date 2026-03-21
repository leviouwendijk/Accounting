import Foundation

extension TaxonomyShared {
    public static func summarizedPresentationDimensions(
        _ facts: [TaxonomyComputedMappedFact],
        source: TaxonomySourceData
    ) -> String? {
        guard !facts.isEmpty else {
            return nil
        }

        let dimensionStrings = facts.flatMap(\.dimensions).map {
            "\($0.axis)=\($0.member)"
        }

        guard !dimensionStrings.isEmpty else {
            return nil
        }

        let counts = Dictionary(
            grouping: dimensionStrings,
            by: { $0 }
        ).mapValues(\.count)

        let ordered = counts.keys.sorted { lhs, rhs in
            let leftCount = counts[lhs] ?? 0
            let rightCount = counts[rhs] ?? 0

            if leftCount == rightCount {
                return lhs < rhs
            }

            return leftCount > rightCount
        }

        let rendered = ordered.prefix(source.maxPresentationDimensionSummaryCount).map {
            key in
            let count = counts[key] ?? 0
            return "\(key) ×\(count)"
        }

        guard !rendered.isEmpty else {
            return nil
        }

        return rendered.joined(separator: ", ")
    }
}

public func summarizedPresentationDimensions(
    _ facts: [TaxonomyComputedMappedFact],
    source: TaxonomySourceData
) -> String? {
    TaxonomyShared.summarizedPresentationDimensions(
        facts,
        source: source
    )
}
