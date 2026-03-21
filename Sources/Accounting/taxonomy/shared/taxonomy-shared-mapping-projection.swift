import Foundation

extension TaxonomyShared {
    public static func globMatch(
        pattern: String,
        text: String
    ) -> Bool {
        let patternScalars = Array(pattern.unicodeScalars)
        let textScalars = Array(text.unicodeScalars)

        var patternIndex = 0
        var textIndex = 0
        var starIndex: Int?
        var matchIndex = 0

        while textIndex < textScalars.count {
            if patternIndex < patternScalars.count,
               (
                   patternScalars[patternIndex] == textScalars[textIndex]
                   || patternScalars[patternIndex] == "?"
               ) {
                patternIndex += 1
                textIndex += 1
                continue
            }

            if patternIndex < patternScalars.count,
               patternScalars[patternIndex] == "*" {
                starIndex = patternIndex
                matchIndex = textIndex
                patternIndex += 1
                continue
            }

            if let starIndex {
                patternIndex = starIndex + 1
                matchIndex += 1
                textIndex = matchIndex
                continue
            }

            return false
        }

        while patternIndex < patternScalars.count,
              patternScalars[patternIndex] == "*" {
            patternIndex += 1
        }

        return patternIndex == patternScalars.count
    }

    public static func csvDimensionBindings(
        from dimensions: [TaxonomyExplicitDimension]
    ) -> [TaxonomyDimensionBinding] {
        dimensions.map {
            TaxonomyDimensionBinding(
                axis: $0.axis,
                member: $0.member
            )
        }
    }

    public static func compileFactsKeepingDimensions(
        mappingRows: [TaxonomyCSVMappingRow],
        rgsBalances: [String: Decimal]
    ) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
        var computedByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] = [:]

        for row in mappingRows {
            let dimensions = sortDimensions(
                csvDimensionBindings(from: row.dimensions)
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

            let dimensions = sortDimensions(
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

    public static func presentationConcepts(
        from link: TaxonomyPresentationLink
    ) -> [String] {
        var concepts = Set<String>()

        for href in link.locators.values {
            let concept = conceptName(from: href)
            guard !concept.isEmpty else {
                continue
            }

            concepts.insert(concept)
        }

        return concepts.sorted()
    }
}

private extension TaxonomyShared {
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
                .filter { globMatch(pattern: pattern, text: $0.key) && $0.value != 0 }

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
                    .filter { globMatch(pattern: term.pattern, text: $0.key) && $0.value != 0 }

                for (code, value) in matches {
                    amount += term.sign * value
                    sourceCodes.insert(code)
                }
            }

            return (amount, Array(sourceCodes).sorted())
        }
    }
}

public func globMatch(
    pattern: String,
    text: String
) -> Bool {
    TaxonomyShared.globMatch(
        pattern: pattern,
        text: text
    )
}

public func csvDimensionBindings(
    from dimensions: [TaxonomyExplicitDimension]
) -> [TaxonomyDimensionBinding] {
    TaxonomyShared.csvDimensionBindings(from: dimensions)
}

public func compileFactsKeepingDimensions(
    mappingRows: [TaxonomyCSVMappingRow],
    rgsBalances: [String: Decimal]
) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
    TaxonomyShared.compileFactsKeepingDimensions(
        mappingRows: mappingRows,
        rgsBalances: rgsBalances
    )
}

public func compileMappedFacts(
    mappings: [TaxonomyCanonicalResolvedMapping],
    rgsBalances: [String: Decimal]
) -> [TaxonomyMappedFactKey: TaxonomyComputedMappedFact] {
    TaxonomyShared.compileMappedFacts(
        mappings: mappings,
        rgsBalances: rgsBalances
    )
}

public func unmatchedRGSCodes(
    mappings: [TaxonomyCanonicalResolvedMapping],
    rgsBalances: [String: Decimal]
) -> [String] {
    TaxonomyShared.unmatchedRGSCodes(
        mappings: mappings,
        rgsBalances: rgsBalances
    )
}

public func projectMappedFactsToConceptFacts(
    _ factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
) -> [String: TaxonomyComputedFact] {
    TaxonomyShared.projectMappedFactsToConceptFacts(factsByKey)
}

public func groupMappedFactsByConceptKeepingDimensions(
    _ factsByKey: [TaxonomyMappedFactKey: TaxonomyComputedMappedFact]
) -> [String: [TaxonomyComputedMappedFact]] {
    TaxonomyShared.groupMappedFactsByConceptKeepingDimensions(factsByKey)
}

public func presentationConcepts(
    from link: TaxonomyPresentationLink
) -> [String] {
    TaxonomyShared.presentationConcepts(from: link)
}
