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

        let accountCodes = output.chart.nodes
            .map(\.codes.code)
            .filter { !$0.isEmpty }

        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: accountCodes,
            codes: accountCodes
        )

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: mappingZIPFileURL,
            taxonomy: bootstrap
        )

        let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
            loadedMapping.resolvedMappings,
            lookup: accountLookup
        )

        let balances = TaxonomyNativeBalanceExtractor.balances(output)

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

        return .init(
            profile: profile,
            bootstrap: bootstrap,
            resolvedMappings: loadedMapping.resolvedMappings,
            canonicalMappings: canonicalMappings,
            balances: balances,
            factsByKey: factsByKey,
            factsByConcept: factsByConcept,
            flattenedFacts: flattenedFacts
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

        let accountCodes = output.chart.nodes
            .map(\.codes.code)
            .filter { !$0.isEmpty }

        let accountLookup = TaxonomyProjection.makeAccountLookup(
            identifiers: accountCodes,
            codes: accountCodes
        )

        let loadedMapping = try TaxonomyLoader.loadGenericMapping(
            zipFileURL: mappingZIPFileURL,
            taxonomy: bootstrap
        )

        let canonicalMappings = TaxonomyProjection.canonicalizeMappings(
            loadedMapping.resolvedMappings,
            lookup: accountLookup
        )

        let currentBalances = TaxonomyNativeBalanceExtractor.balances(
            period: output.assembled.current,
            chart: output.chart
        )

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
            previousRange: output.assembled.previous?.range
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
