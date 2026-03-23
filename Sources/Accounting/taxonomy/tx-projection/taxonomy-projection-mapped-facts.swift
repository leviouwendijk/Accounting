import Foundation

extension TaxonomyProjection {
    public static func compileFactsKeepingDimensions(
        mappingRows: [TaxonomyCSVMappingRow],
        rgsBalances: [String: Decimal]
    ) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
        var computedByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] = [:]

        for row in mappingRows {
            let dimensions = TaxonomyShared.sortDimensions(
                TaxonomyShared.csvDimensionBindings(from: row.dimensions)
            )

            let result = amountAndSourceCodes(
                for: row.source,
                balances: rgsBalances
            )

            guard result.amount != 0 else {
                continue
            }

            let fact = TaxonomyComputedMappedFact(
                concept: row.targetConcept,
                amount: result.amount,
                dimensions: dimensions,
                sourceCodes: result.sourceCodes.sorted()
            )

            computedByKey[factKey(from: fact)] = fact
        }

        return computedByKey
    }

    public static func compileMappedFacts(
        mappings: [TaxonomyCanonicalResolvedMapping],
        rgsBalances: [String: Decimal]
    ) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
        var groupedAmountByKey: [TaxonomyMappedFactKey: Decimal] = [:]
        var groupedCodesByKey: [TaxonomyMappedFactKey: Set<String>] = [:]

        for mapping in mappings {
            let amount = rgsBalances[mapping.matchedCode] ?? 0
            guard amount != 0 else {
                continue
            }

            let dimensions = TaxonomyShared.sortDimensions(
                mapping.dimensions.map {
                    TaxonomyDimensionBinding(
                        axis: $0.axis,
                        member: $0.member
                    )
                }
            )

            let key = TaxonomyMappedFactKey(
                concept: mapping.targetConcept,
                dimensions: dimensions
            )

            groupedAmountByKey[key, default: 0] += amount
            groupedCodesByKey[key, default: []].insert(mapping.matchedCode)
        }

        var out: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] = [:]

        for (key, amount) in groupedAmountByKey {
            out[key] = TaxonomyComputedMappedFact(
                concept: key.concept,
                amount: amount,
                dimensions: key.dimensions,
                sourceCodes: Array(groupedCodesByKey[key] ?? []).sorted()
            )
        }

        return out
    }

    public static func compileMappedFactsFromNodeMappings(
        mappings: [TaxonomyNormalizedResolvedMapping],
        chart: CompiledChart,
        rgsBalances: [String: Decimal]
    ) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
        let codeById = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) }
        )

        var groupedAmountByKey: [TaxonomyMappedFactKey: Decimal] = [:]
        var groupedCodesByKey: [TaxonomyMappedFactKey: Set<String>] = [:]

        for mapping in mappings {
            let sourceCode: String = codeById[mapping.sourceNodeId] ?? mapping.sourceCode
            guard !sourceCode.isEmpty else {
                continue
            }

            let amount = rgsBalances[sourceCode] ?? 0
            guard amount != 0 else {
                continue
            }

            let dimensions = TaxonomyShared.sortDimensions(
                mapping.dimensions.map {
                    TaxonomyDimensionBinding(
                        axis: $0.axis,
                        member: $0.member
                    )
                }
            )

            let key = TaxonomyMappedFactKey(
                concept: mapping.targetConcept,
                dimensions: dimensions
            )

            groupedAmountByKey[key, default: 0] += amount
            groupedCodesByKey[key, default: []].insert(sourceCode)
        }

        var out: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] = [:]

        for (key, amount) in groupedAmountByKey {
            out[key] = TaxonomyComputedMappedFact(
                concept: key.concept,
                amount: amount,
                dimensions: key.dimensions,
                sourceCodes: Array(groupedCodesByKey[key] ?? []).sorted()
            )
        }

        return out
    }

    public static func unmatchedRGSCodes(
        mappings: [TaxonomyCanonicalResolvedMapping],
        rgsBalances: [String: Decimal]
    ) -> [String] {
        let mappedCodes = Set(mappings.map(\.matchedCode))

        return rgsBalances.keys
            .filter { code in
                guard let amount = rgsBalances[code] else {
                    return false
                }

                return amount != 0 && !mappedCodes.contains(code)
            }
            .sorted()
    }

    public static func projectMappedFactsToConceptFacts(
        _ factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
    ) -> [String: TaxonomyComputedFact] {
        var totalsByConcept: [String: Decimal] = [:]

        for fact in factsByKey.values {
            totalsByConcept[fact.concept, default: 0] += fact.amount
        }

        var out: [String: TaxonomyComputedFact] = [:]
        for (concept, amount) in totalsByConcept {
            out[concept] = TaxonomyComputedFact(
                concept: concept,
                amount: amount
            )
        }

        return out
    }

    public static func groupMappedFactsByConceptKeepingDimensions(
        _ factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
    ) -> [String: [TaxonomyComputedMappedFact]] {
        var out: [String: [TaxonomyComputedMappedFact]] = [:]

        for fact in factsByKey.values {
            out[fact.concept, default: []].append(fact)
        }

        for concept in out.keys {
            out[concept]?.sort { lhs, rhs in
                let lhsDimensions = lhs.dimensions.map { "\($0.axis)=\($0.member)" }
                let rhsDimensions = rhs.dimensions.map { "\($0.axis)=\($0.member)" }

                if lhsDimensions == rhsDimensions {
                    return lhs.amount < rhs.amount
                }

                return lhsDimensions.lexicographicallyPrecedes(rhsDimensions)
            }
        }

        return out
    }

    static func amountAndSourceCodes(
        for source: TaxonomyCSVMappingSource,
        balances: [String: Decimal]
    ) -> (
        amount: Decimal,
        sourceCodes: [String]
    ) {
        switch source {
        case .exact(let code):
            let amount = balances[code] ?? 0
            let sourceCodes = amount == 0 ? [] : [code]
            return (amount, sourceCodes)

        case .prefix(let prefix):
            let matches = balances
                .filter { $0.key.hasPrefix(prefix) && $0.value != 0 }

            let amount = matches.reduce(Decimal.zero) { partial, pair in
                partial + pair.value
            }

            let sourceCodes = matches.keys.sorted()
            return (amount, sourceCodes)

        case .glob(let pattern):
            let matches = balances
                .filter { TaxonomyShared.globMatch(pattern: pattern, text: $0.key) && $0.value != 0 }

            let amount = matches.reduce(Decimal.zero) { partial, pair in
                partial + pair.value
            }

            let sourceCodes = matches.keys.sorted()
            return (amount, sourceCodes)

        case .group(let terms):
            var amount: Decimal = 0
            var sourceCodes = Set<String>()

            for term in terms {
                let matches = balances
                    .filter { TaxonomyShared.globMatch(pattern: term.pattern, text: $0.key) && $0.value != 0 }

                for (code, value) in matches {
                    amount += term.sign * value
                    sourceCodes.insert(code)
                }
            }

            return (amount, Array(sourceCodes).sorted())
        }
    }
}
