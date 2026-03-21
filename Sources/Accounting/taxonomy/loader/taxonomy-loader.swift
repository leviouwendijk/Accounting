import Foundation

extension TaxonomyLoader {
    public static func load(
        config: TaxonomyLoadConfig
    ) throws -> LoadedTaxonomy {
        let entrypointURL = try urlFromStringOrPath(config.source.entrypoint)
        let entrypointXML = try fetchText(from: entrypointURL)

        let refs = try TaxonomyEntrypointParser.parse(
            entrypointXML,
            source: config.source
        )

        let selectedPresentationURLs = resolveSelectedPresentationURLs(
            refs: refs,
            entrypointURL: entrypointURL,
            wantedPresentations: config.wantedPresentations
        )

        let loadedPresentations = try loadPresentations(
            from: selectedPresentationURLs
        )

        let labelsByConcept = try loadLabels(
            refs: refs,
            entrypointURL: entrypointURL,
            labelHrefs: config.labelHrefs
        )

        return LoadedTaxonomy(
            source: config.source,
            entrypointURL: entrypointURL,
            entrypointBasename: entrypointURL.deletingPathExtension().lastPathComponent,
            refs: refs,
            selectedPresentationURLs: selectedPresentationURLs,
            selectedPresentationLinks: loadedPresentations.selectedLinks,
            allPresentationLinksByURL: loadedPresentations.linksByURL,
            labelsByConcept: labelsByConcept
        )
    }
}
