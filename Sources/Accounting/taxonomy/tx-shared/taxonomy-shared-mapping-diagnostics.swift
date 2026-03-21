import Foundation

extension TaxonomyShared {
    public static func mappingHitCountsByCode(
        mappings: [TaxonomyCanonicalResolvedMapping]
    ) -> [String: Int] {
        var counts: [String: Int] = [:]

        for mapping in mappings {
            counts[mapping.matchedCode, default: 0] += 1
        }

        return counts
    }

    public static func renderDemoBalanceCoverage(
        mappings: [TaxonomyCanonicalResolvedMapping],
        rgsBalances: [String: Decimal],
        limitPerCode: Int = 8
    ) {
        let conceptsByCode = TaxonomyTester.conceptsByCode(mappings: mappings)

        print("demo balance coverage:")
        for code in rgsBalances.keys.sorted() {
            let amount = rgsBalances[code] ?? 0
            let concepts = Array(conceptsByCode[code] ?? []).sorted()

            print("  \(code): \(decimalString(amount))")

            if concepts.isEmpty {
                print("    -> unmapped")
                continue
            }

            for concept in concepts.prefix(limitPerCode) {
                print("    -> \(concept)")
            }

            if concepts.count > limitPerCode {
                print("    -> ... +\(concepts.count - limitPerCode) more")
            }
        }
    }

    public static func renderCanonicalSourceCodes(
        mappings: [TaxonomyCanonicalResolvedMapping],
        prefix: String? = nil,
        limit: Int = 200
    ) {
        let grouped = Dictionary(grouping: mappings, by: \.matchedCode)
        let sortedCodes = grouped.keys.sorted().filter { code in
            guard let prefix else {
                return true
            }

            return code.hasPrefix(prefix)
        }

        print("canonical mapping source codes:")
        for code in sortedCodes.prefix(limit) {
            let concepts = Set(grouped[code, default: []].map(\.targetConcept))
            let renderedConcepts = concepts.sorted().joined(separator: ", ")
            print("  \(code) -> \(renderedConcepts)")
        }

        if sortedCodes.count > limit {
            print("  ... +\(sortedCodes.count - limit) more")
        }
    }

    public static func renderUsedProjectCoverage(
        mappings: [TaxonomyCanonicalResolvedMapping],
        balances: [String: Decimal],
        limitUnmatched: Int = 60
    ) {
        let unmatched = TaxonomyProjection.unmatchedRGSCodes(
            mappings: mappings,
            rgsBalances: balances
        )

        let usedCodes = balances.keys
            .filter { (balances[$0] ?? 0) != 0 }
            .sorted()

        print("used project coverage:")
        print("  used codes: \(usedCodes.count)")
        print("  unmatched used codes: \(unmatched.count)")

        if unmatched.isEmpty {
            print("  all non-zero codes are mapped")
            return
        }

        print("  unmatched:")
        for code in unmatched.prefix(limitUnmatched) {
            let amount = balances[code] ?? 0
            print("    \(code): \(decimalString(amount))")
        }

        if unmatched.count > limitUnmatched {
            print("    ... +\(unmatched.count - limitUnmatched) more")
        }
    }

    public static func inspectUnmatchedProjectCodes(
        mappings: [TaxonomyCanonicalResolvedMapping],
        balances: [String: Decimal],
        limitPerCode: Int = 5
    ) {
        let unmatched = TaxonomyProjection.unmatchedRGSCodes(
            mappings: mappings,
            rgsBalances: balances
        )

        print("unmatched project codes:")
        if unmatched.isEmpty {
            print("  none")
            return
        }

        let suggestionsByCode = suggestNearbyMappedCodes(
            unmatchedCodes: unmatched,
            mappings: mappings,
            limitPerCode: limitPerCode
        )

        for code in unmatched {
            let amount = balances[code] ?? 0
            print("  \(code): \(decimalString(amount))")

            let suggestions = suggestionsByCode[code, default: []]
            if suggestions.isEmpty {
                print("    -> no nearby mapped codes found")
                continue
            }

            for suggestion in suggestions {
                let concepts = suggestion.targetConcepts.joined(separator: ", ")
                if concepts.isEmpty {
                    print("    -> \(suggestion.suggestedCode) [score \(suggestion.score)]")
                } else {
                    print("    -> \(suggestion.suggestedCode) [score \(suggestion.score)] :: \(concepts)")
                }
            }
        }
    }

    public static func commonPrefixLength(
        _ lhs: String,
        _ rhs: String
    ) -> Int {
        let left = Array(lhs)
        let right = Array(rhs)
        let count = Swift.min(left.count, right.count)

        var index = 0
        while index < count, left[index] == right[index] {
            index += 1
        }

        return index
    }

    public static func codeFamilyPrefixes(
        _ code: String
    ) -> [String] {
        guard !code.isEmpty else {
            return []
        }

        var out: [String] = []

        if code.count >= 1 {
            out.append(String(code.prefix(1)))
        }

        if code.count >= 2 {
            out.append(String(code.prefix(2)))
        }

        if code.count >= 4 {
            out.append(String(code.prefix(4)))
        }

        if code.count >= 6 {
            out.append(String(code.prefix(6)))
        }

        return Array(NSOrderedSet(array: out)) as? [String] ?? out
    }

    public static func suggestionScore(
        query: String,
        candidate: String
    ) -> Int {
        let prefix = commonPrefixLength(query, candidate)
        let familyOverlap = Set(codeFamilyPrefixes(query))
            .intersection(Set(codeFamilyPrefixes(candidate)))
            .count

        let lengthPenalty = abs(query.count - candidate.count)

        return (prefix * 10) + (familyOverlap * 8) - lengthPenalty
    }

    public static func suggestNearbyMappedCodes(
        unmatchedCodes: [String],
        mappings: [TaxonomyCanonicalResolvedMapping],
        limitPerCode: Int = 5
    ) -> [String: [TaxonomyMappingSuggestion]] {
        let grouped = Dictionary(grouping: mappings, by: \.matchedCode)

        let knownCodes = grouped.keys.sorted()

        return Dictionary(uniqueKeysWithValues: unmatchedCodes.map { unmatched in
            let suggestions = knownCodes
                .map { candidate -> TaxonomyMappingSuggestion in
                    let concepts = Set(grouped[candidate, default: []].map(\.targetConcept))
                    return TaxonomyMappingSuggestion(
                        unmatchedCode: unmatched,
                        suggestedCode: candidate,
                        score: suggestionScore(query: unmatched, candidate: candidate),
                        targetConcepts: concepts.sorted()
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.score == rhs.score {
                        return lhs.suggestedCode < rhs.suggestedCode
                    }

                    return lhs.score > rhs.score
                }
                .prefix(limitPerCode)

            return (unmatched, Array(suggestions))
        })
    }

    public static func renderMappingSuggestions(
        unmatchedCodes: [String],
        mappings: [TaxonomyCanonicalResolvedMapping],
        limitPerCode: Int = 5
    ) {
        let suggestionsByCode = suggestNearbyMappedCodes(
            unmatchedCodes: unmatchedCodes,
            mappings: mappings,
            limitPerCode: limitPerCode
        )

        print("mapping suggestions:")
        if unmatchedCodes.isEmpty {
            print("  none")
            return
        }

        for code in unmatchedCodes {
            print("  \(code):")
            let suggestions = suggestionsByCode[code, default: []]

            if suggestions.isEmpty {
                print("    -> none")
                continue
            }

            for suggestion in suggestions {
                let concepts = suggestion.targetConcepts.joined(separator: ", ")
                if concepts.isEmpty {
                    print("    -> \(suggestion.suggestedCode) [score \(suggestion.score)]")
                } else {
                    print("    -> \(suggestion.suggestedCode) [score \(suggestion.score)] :: \(concepts)")
                }
            }
        }
    }
}

