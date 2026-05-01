import Accounting
import Foundation

public struct TaxonomyCanonicalNormalizationResult: Sendable {
    public let kept: [TaxonomyCanonicalResolvedMapping]
    public let droppedExactDuplicates: [TaxonomyCanonicalResolvedMapping]
    public let droppedAncestorMappings: [TaxonomyCanonicalResolvedMapping]

    public init(
        kept: [TaxonomyCanonicalResolvedMapping],
        droppedExactDuplicates: [TaxonomyCanonicalResolvedMapping],
        droppedAncestorMappings: [TaxonomyCanonicalResolvedMapping]
    ) {
        self.kept = kept
        self.droppedExactDuplicates = droppedExactDuplicates
        self.droppedAncestorMappings = droppedAncestorMappings
    }
}

public enum TaxonomySourceNormalizer {
    public static func normalizeCanonicalMappings(
        _ mappings: [TaxonomyCanonicalResolvedMapping],
        chart: CompiledChart
    ) -> TaxonomyCanonicalNormalizationResult {
        let deduped = dedupeExactMappings(mappings)

        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        let idByCode: [String: Int] = Dictionary(
            uniqueKeysWithValues: chart.nodes.compactMap { node -> (String, Int)? in
                let code = node.codes.code
                guard !code.isEmpty else {
                    return nil
                }

                return (code, node.id)
            }
        )

        let maps = try? RGSAssembler.makeMaps(from: chart)
        let parentById = maps?.parentById ?? [:]

        let grouped = Dictionary(
            grouping: deduped.kept,
            by: { mapping in
                TaxonomyShared.sortDimensions(
                    mapping.dimensions.map {
                        TaxonomyDimensionBinding(
                            axis: $0.axis,
                            member: $0.member
                        )
                    }
                )
            }
        )

        var kept: [TaxonomyCanonicalResolvedMapping] = []
        var droppedAncestors: [TaxonomyCanonicalResolvedMapping] = []

        for (_, group) in grouped {
            let pruned = pruneAncestorsWithinDimensionGroup(
                group,
                idByCode: idByCode,
                codeById: codeById,
                parentById: parentById
            )

            kept.append(contentsOf: pruned.kept)
            droppedAncestors.append(contentsOf: pruned.dropped)
        }

        return TaxonomyCanonicalNormalizationResult(
            kept: kept,
            droppedExactDuplicates: deduped.dropped,
            droppedAncestorMappings: droppedAncestors
        )
    }

    private static func dedupeExactMappings(
        _ mappings: [TaxonomyCanonicalResolvedMapping]
    ) -> (
        kept: [TaxonomyCanonicalResolvedMapping],
        dropped: [TaxonomyCanonicalResolvedMapping]
    ) {
        struct Key: Hashable {
            let matchedCode: String
            let targetConcept: String
            let dimensions: [TaxonomyDimensionBinding]
        }

        var seen = Set<Key>()
        var kept: [TaxonomyCanonicalResolvedMapping] = []
        var dropped: [TaxonomyCanonicalResolvedMapping] = []

        for mapping in mappings {
            let dimensions = TaxonomyShared.sortDimensions(
                mapping.dimensions.map {
                    TaxonomyDimensionBinding(
                        axis: $0.axis,
                        member: $0.member
                    )
                }
            )

            let key = Key(
                matchedCode: mapping.matchedCode,
                targetConcept: mapping.targetConcept,
                dimensions: dimensions
            )

            if seen.insert(key).inserted {
                kept.append(mapping)
            } else {
                dropped.append(mapping)
            }
        }

        return (kept, dropped)
    }

    private static func pruneAncestorsWithinDimensionGroup(
        _ mappings: [TaxonomyCanonicalResolvedMapping],
        idByCode: [String: Int],
        codeById: [Int: String],
        parentById: [Int: Int]
    ) -> (
        kept: [TaxonomyCanonicalResolvedMapping],
        dropped: [TaxonomyCanonicalResolvedMapping]
    ) {
        let groupedByConcept = Dictionary(
            grouping: mappings,
            by: \.targetConcept
        )

        var kept: [TaxonomyCanonicalResolvedMapping] = []
        var dropped: [TaxonomyCanonicalResolvedMapping] = []

        for (_, conceptMappings) in groupedByConcept {
            let mappedIds = Set(
                conceptMappings.compactMap { mapping in
                    idByCode[mapping.matchedCode]
                }
            )

            for mapping in conceptMappings {
                guard let id = idByCode[mapping.matchedCode] else {
                    kept.append(mapping)
                    continue
                }

                if hasMappedDescendant(
                    id: id,
                    mappedIds: mappedIds,
                    parentById: parentById
                ) {
                    dropped.append(mapping)
                } else {
                    kept.append(mapping)
                }
            }
        }

        return (kept, dropped)
    }

    private static func hasMappedDescendant(
        id: Int,
        mappedIds: Set<Int>,
        parentById: [Int: Int]
    ) -> Bool {
        for candidate in mappedIds where candidate != id {
            var current: Int? = candidate

            while let node = current {
                if node == id {
                    return true
                }

                current = parentById[node]
            }
        }

        return false
    }
}

extension TaxonomySourceNormalizer {
    public static func normalizeMappingsToNodeIds(
        _ mappings: [TaxonomyCanonicalResolvedMapping],
        chart: CompiledChart
    ) -> [TaxonomyNormalizedResolvedMapping] {
        let deduped = dedupeExactMappings(mappings)

        let idByCode: [String: Int] = Dictionary(
            uniqueKeysWithValues: chart.nodes.compactMap { node -> (String, Int)? in
                let code = node.codes.code
                guard !code.isEmpty else {
                    return nil
                }

                return (code, node.id)
            }
        )

        let maps = try? RGSAssembler.makeMaps(from: chart)
        let parentById = maps?.parentById ?? [:]

        let grouped = Dictionary(
            grouping: deduped.kept,
            by: { mapping in
                TaxonomyMappedFactKey(
                    concept: mapping.targetConcept,
                    dimensions: TaxonomyShared.sortDimensions(
                        mapping.dimensions.map {
                            TaxonomyDimensionBinding(
                                axis: $0.axis,
                                member: $0.member
                            )
                        }
                    )
                )
            }
        )

        var out: [TaxonomyNormalizedResolvedMapping] = []

        for (key, group) in grouped {
            let nodeIds = group.compactMap { idByCode[$0.matchedCode] }
            let reduced = TaxonomyNodeReducer.reduceToTopLevelUniqueNodes(
                nodeIds,
                parentById: parentById
            )

            let codeById = Dictionary(
                uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
            )

            for nodeId in reduced {
                guard let sourceCode = codeById[nodeId], !sourceCode.isEmpty else {
                    continue
                }

                out.append(
                    TaxonomyNormalizedResolvedMapping(
                        targetConcept: key.concept,
                        dimensions: key.dimensions.map {
                            TaxonomyExplicitDimension(
                                axis: $0.axis,
                                member: $0.member
                            )
                        },
                        sourceNodeId: nodeId,
                        sourceCode: sourceCode
                    )
                )
            }
        }

        return out
    }
}
