import Foundation

extension TaxonomyLoader {
    static func resolveSelectedPresentationURLs(
        refs: TaxonomyEntrypointRefs,
        entrypointURL: URL,
        wantedPresentations: [String]
    ) -> [URL] {
        refs.presentation
            .compactMap { ref in
                TaxonomyShared.resolveURL(ref.href, relativeTo: entrypointURL)
            }
            .filter { url in
                guard !wantedPresentations.isEmpty else {
                    return true
                }

                let absoluteString = url.absoluteString.lowercased()
                let lastPathComponent = url.lastPathComponent.lowercased()

                return wantedPresentations.contains { wanted in
                    let needle = wanted.lowercased()
                    return absoluteString.contains(needle)
                        || lastPathComponent.contains(needle)
                }
            }
    }

    static func loadPresentations(
        from urls: [URL]
    ) throws -> (
        selectedLinks: [TaxonomyPresentationLink],
        linksByURL: [String: [TaxonomyPresentationLink]]
    ) {
        var linksByURL: [String: [TaxonomyPresentationLink]] = [:]
        var selectedLinks: [TaxonomyPresentationLink] = []

        for url in urls {
            let xml = try fetchText(from: url)
            let links = try TaxonomyPresentationParser.parse(xml)

            linksByURL[url.absoluteString] = links
            selectedLinks.append(contentsOf: links)
        }

        return (
            selectedLinks: selectedLinks,
            linksByURL: linksByURL
        )
    }

    static func loadLabels(
        refs: TaxonomyEntrypointRefs,
        entrypointURL: URL,
        labelHrefs: [String]
    ) throws -> [String: String] {
        let labelURLs: [URL]

        if !labelHrefs.isEmpty {
            labelURLs = labelHrefs.compactMap {
                TaxonomyShared.resolveURL($0, relativeTo: entrypointURL)
            }
        } else {
            labelURLs = refs.labels.compactMap { ref in
                TaxonomyShared.resolveURL(ref.href, relativeTo: entrypointURL)
            }
        }

        var dedupedLabelURLs: [URL] = []
        var seen: Set<String> = []

        for url in labelURLs {
            if seen.insert(url.absoluteString).inserted {
                dedupedLabelURLs.append(url)
            }
        }

        var labelsByConcept: [String: String] = [:]

        for labelURL in dedupedLabelURLs {
            let xml = try fetchText(from: labelURL)
            let parsed = try TaxonomyLabelParser.parse(xml)

            for (concept, label) in parsed where labelsByConcept[concept] == nil {
                labelsByConcept[concept] = label
            }
        }

        return labelsByConcept
    }
}
