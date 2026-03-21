import Foundation

extension TaxonomyLoader {
    static func resolveSelectedPresentationURLs(
        refs: TaxonomyEntrypointRefs,
        entrypointURL: URL,
        wantedPresentations: [String]
    ) -> [URL] {
        refs.presentation
            .compactMap { ref in
                resolveURL(ref.href, relativeTo: entrypointURL)
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
        let selectedLabelRefs: [TaxonomyLinkbaseRef]

        if labelHrefs.isEmpty {
            selectedLabelRefs = refs.labels
        } else {
            selectedLabelRefs = refs.labels.filter { ref in
                let href = ref.href.lowercased()
                return labelHrefs.contains { wanted in
                    href.contains(wanted.lowercased())
                }
            }
        }

        var labelsByConcept: [String: String] = [:]

        for labelRef in selectedLabelRefs {
            guard let labelURL = resolveURL(
                labelRef.href,
                relativeTo: entrypointURL
            ) else {
                continue
            }

            let xml = try fetchText(from: labelURL)
            let parsed = try TaxonomyLabelParser.parse(xml)

            for (concept, label) in parsed where labelsByConcept[concept] == nil {
                labelsByConcept[concept] = label
            }
        }

        return labelsByConcept
    }
}
