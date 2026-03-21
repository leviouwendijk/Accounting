import Foundation

extension TaxonomyProberRunner {
    public func loadBootstrap() throws -> TaxonomyProbeBootstrap {
        let entrypointURL = try urlFromStringOrPath(config.entrypoint)
        let entrypointXML = try fetchText(from: entrypointURL)
        let refs = try TaxonomyEntrypointParser.parse(
            entrypointXML,
            source: config.source
        )

        let selectedPresentationURLs = refs.presentation.compactMap { ref in
            resolveURL(
                ref.href,
                relativeTo: entrypointURL
            )
        }
        .filter { url in
            if config.wantedPresentations.isEmpty {
                return true
            }

            let absoluteString = url.absoluteString.lowercased()
            let lastPathComponent = url.lastPathComponent.lowercased()

            return config.wantedPresentations.contains { wanted in
                let normalizedWanted = wanted.lowercased()
                return absoluteString.contains(normalizedWanted)
                    || lastPathComponent.contains(normalizedWanted)
            }
        }

        var allPresentationLinksByURL: [String: [TaxonomyPresentationLink]] = [:]
        var selectedLinks: [TaxonomyPresentationLink] = []

        for presentationURL in selectedPresentationURLs {
            let xml = try fetchText(from: presentationURL)
            let links = try TaxonomyPresentationParser.parse(xml)

            allPresentationLinksByURL[presentationURL.absoluteString] = links
            selectedLinks.append(contentsOf: links)
        }

        var labelsByConcept: [String: String] = [:]

        let selectedLabelRefs: [TaxonomyLinkbaseRef]
        if config.labelHrefs.isEmpty {
            selectedLabelRefs = refs.labels
        } else {
            selectedLabelRefs = refs.labels.filter { ref in
                let href = ref.href.lowercased()
                return config.labelHrefs.contains { wanted in
                    href.contains(wanted.lowercased())
                }
            }
        }

        for labelRef in selectedLabelRefs {
            guard let labelURL = resolveURL(
                labelRef.href,
                relativeTo: entrypointURL
            ) else {
                continue
            }

            let xml = try fetchText(from: labelURL)
            let parsed = try TaxonomyLabelParser.parse(xml)

            for (concept, label) in parsed {
                if labelsByConcept[concept] == nil {
                    labelsByConcept[concept] = label
                }
            }
        }

        return TaxonomyProbeBootstrap(
            entrypointURL: entrypointURL,
            entrypointBasename: entrypointURL.deletingPathExtension().lastPathComponent,
            refs: refs,
            selectedPresentationURLs: selectedPresentationURLs,
            selectedLinks: selectedLinks,
            allPresentationLinksByURL: allPresentationLinksByURL,
            labelsByConcept: labelsByConcept
        )
    }
}
