import Foundation

public enum TaxonomyProjector {
    public static func projectCompile(
        _ output: NativeCompileOutput,
        profile: String,
        presentation: [String]
    ) throws -> TaxonomyCompileProjectionOutput {
        let sourceProfile = try resolveProfile(profile)
        let source = sourceProfile.data.applying(
            overrides: .init(
                wantedPresentations: presentation.isEmpty ? nil : presentation
            )
        )

        let bootstrap = try TaxonomyLoader.load(
            config: .init(
                source: source,
                wantedPresentations: source.wantedPresentations,
                labelHrefs: source.labelHrefs
            )
        )

        let mappingZIPURL = try TaxonomyShared.urlFromStringOrPath(
            source.mappingZIP
        )
        let mappingZIPData = try TaxonomyLoader.fetchData(
            from: mappingZIPURL
        )
        let mappingZIPFileURL = try TaxonomyLoader.writeTempFile(
            data: mappingZIPData,
            suffix: "zip"
        )
        defer {
            try? FileManager.default.removeItem(at: mappingZIPFileURL)
        }

        // let accountCodes = output.chart.nodes
        //     .map(\.codes.code)
        //     .filter { !$0.isEmpty }

        // let accountLookup = TaxonomyProjection.makeAccountLookup(
        //     identifiers: accountCodes,
        //     codes: accountCodes
        // )


        // let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
        //     loadedMapping.resolvedMappings,
        //     lookup: accountLookup
        // )

        // let canonicalMappings = dedupeCanonicalMappings(
        //     TaxonomyProjection.canonicalizeMappings(
        //         loadedMapping.resolvedMappings,
        //         lookup: accountLookup
        //     )
        // )

        let balances = TaxonomyNativeBalanceExtractor.balances(output)

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: mappingZIPFileURL,
            taxonomy: bootstrap
        )

        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: Array(balances.keys),
            codes: Array(balances.keys)
        )

        let canonicalMappingsRaw = TaxonomyProjection.canonicalizeMappings(
            loadedMapping.resolvedMappings,
            lookup: accountLookup
        )

        let normalization = TaxonomySourceNormalizer.normalizeCanonicalMappings(
            canonicalMappingsRaw,
            chart: output.chart
        )

        let canonicalMappings = normalization.kept

        let factsByKey = TaxonomyProjection.compileMappedFacts(
            mappings: canonicalMappings,
            rgsBalances: balances
        )

        let factsByConcept = TaxonomyProjection.groupMappedFactsByConceptKeepingDimensions(
            factsByKey
        )

        let flattenedFacts = TaxonomyProjection.projectMappedFactsToConceptFacts(
            factsByKey
        )

        let diagnostics = TaxonomyProjectionDiagnosticsBuilder.build(
            bootstrap: bootstrap,
            genericMapping: loadedMapping,
            presentation: presentation,
            currentBalances: balances,
            canonicalMappings: canonicalMappings
        )

        return .init(
            profile: profile,
            bootstrap: bootstrap,
            resolvedMappings: loadedMapping.resolvedMappings,
            canonicalMappings: canonicalMappings,
            balances: balances,
            factsByKey: factsByKey,
            factsByConcept: factsByConcept,
            flattenedFacts: flattenedFacts,
            diagnostics: diagnostics
        )
    }

    public static func projectPeriod(
        _ output: NativePeriodCompileOutput,
        profile: String,
        presentation: [String]
    ) throws -> TaxonomyPeriodProjectionOutput {
        let sourceProfile = try resolveProfile(profile)
        let source = sourceProfile.data.applying(
            overrides: .init(
                wantedPresentations: presentation.isEmpty ? nil : presentation
            )
        )

        let bootstrap = try TaxonomyLoader.load(
            config: .init(
                source: source,
                wantedPresentations: source.wantedPresentations,
                labelHrefs: source.labelHrefs
            )
        )

        let mappingZIPURL = try TaxonomyShared.urlFromStringOrPath(
            source.mappingZIP
        )
        let mappingZIPData = try TaxonomyLoader.fetchData(
            from: mappingZIPURL
        )
        let mappingZIPFileURL = try TaxonomyLoader.writeTempFile(
            data: mappingZIPData,
            suffix: "zip"
        )
        defer {
            try? FileManager.default.removeItem(at: mappingZIPFileURL)
        }

        // let accountCodes = output.chart.nodes
        //     .map(\.codes.code)
        //     .filter { !$0.isEmpty }

        // let accountLookup = TaxonomyProjection.makeAccountLookup(
        //     identifiers: accountCodes,
        //     codes: accountCodes
        // )

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: mappingZIPFileURL,
            taxonomy: bootstrap
        )

        // let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
        //     loadedMapping.resolvedMappings,
        //     lookup: accountLookup
        // )

        // let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
        //     loadedMapping.resolvedMappings,
        //     lookup: accountLookup
        // )

        // let canonicalMappings = dedupeCanonicalMappings(
        //     TaxonomyProjection.canonicalizeMappings(
        //         loadedMapping.resolvedMappings,
        //         lookup: accountLookup
        //     )
        // )

        let currentBalances = TaxonomyNativeBalanceExtractor.balances(
            period: output.assembled.current,
            chart: output.chart
        )

        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: Array(currentBalances.keys),
            codes: Array(currentBalances.keys)
        )

        let canonicalMappingsRaw = TaxonomyProjection.canonicalizeMappings(
            loadedMapping.resolvedMappings,
            lookup: accountLookup
        )

        let normalization = TaxonomySourceNormalizer.normalizeCanonicalMappings(
            canonicalMappingsRaw,
            chart: output.chart
        )

        let canonicalMappings = normalization.kept


        let currentFactsByKey = TaxonomyProjection.compileMappedFacts(
            mappings: canonicalMappings,
            rgsBalances: currentBalances
        )

        let currentFactsByConcept = TaxonomyProjection.groupMappedFactsByConceptKeepingDimensions(
            currentFactsByKey
        )

        let currentFlattenedFacts = TaxonomyProjection.projectMappedFactsToConceptFacts(
            currentFactsByKey
        )

        // diagnostics based on current
        let diagnostics = TaxonomyProjectionDiagnosticsBuilder.build(
            bootstrap: bootstrap,
            genericMapping: loadedMapping,
            presentation: presentation,
            currentBalances: currentBalances,
            canonicalMappings: canonicalMappings
        )

        let previousBalances = output.assembled.previous.map {
            TaxonomyNativeBalanceExtractor.balances(
                period: $0,
                chart: output.chart
            )
        }

        let previousFactsByKey = previousBalances.map {
            TaxonomyProjection.compileMappedFacts(
                mappings: canonicalMappings,
                rgsBalances: $0
            )
        }

        let previousFactsByConcept = previousFactsByKey.map {
            TaxonomyProjection.groupMappedFactsByConceptKeepingDimensions($0)
        }

        let previousFlattenedFacts = previousFactsByKey.map {
            TaxonomyProjection.projectMappedFactsToConceptFacts($0)
        }

        return .init(
            profile: profile,
            bootstrap: bootstrap,
            resolvedMappings: loadedMapping.resolvedMappings,
            canonicalMappings: canonicalMappings,
            currentBalances: currentBalances,
            currentFactsByKey: currentFactsByKey,
            currentFactsByConcept: currentFactsByConcept,
            currentFlattenedFacts: currentFlattenedFacts,
            previousBalances: previousBalances,
            previousFactsByKey: previousFactsByKey,
            previousFactsByConcept: previousFactsByConcept,
            previousFlattenedFacts: previousFlattenedFacts,
            currentRange: output.assembled.current.range,
            previousRange: output.assembled.previous?.range,
            diagnostics: diagnostics
        )
    }

    private static func resolveProfile(
        _ raw: String
    ) throws -> TaxonomySourceProfile {
        guard let profile = TaxonomySourceProfile(rawValue: raw) else {
            throw TaxonomyProjectionError.invalidProfile(raw)
        }
        return profile
    }

    private static func dedupeCanonicalMappings(
        _ mappings: [TaxonomyCanonicalResolvedMapping]
    ) -> [TaxonomyCanonicalResolvedMapping] {
        struct Key: Hashable {
            let matchedCode: String
            let targetConcept: String
            let dimensions: [TaxonomyDimensionKey]
        }

        var seen = Set<Key>()
        var out: [TaxonomyCanonicalResolvedMapping] = []

        for mapping in mappings {
            let dims = mapping.dimensions.map {
                TaxonomyDimensionKey(
                    axis: $0.axis,
                    member: $0.member
                )
            }

            let key = Key(
                matchedCode: mapping.matchedCode,
                targetConcept: mapping.targetConcept,
                dimensions: dims
            )

            if seen.insert(key).inserted {
                out.append(mapping)
            }
        }

        return out
    }
}

private struct TaxonomyDimensionKey: Hashable {
    let axis: String
    let member: String
}

public enum TaxonomyProjectionError: LocalizedError, Sendable {
    case invalidProfile(String)

    public var errorDescription: String? {
        switch self {
        case .invalidProfile(let raw):
            return "Invalid taxonomy profile '\(raw)'."
        }
    }
}
