import Foundation

extension TaxonomyPresentation {
    public static func presentationConcepts(
        from link: TaxonomyPresentationLink
    ) -> [String] {
        var concepts = Set<String>()

        for href in link.locators.values {
            let concept = TaxonomyShared.conceptName(from: href)
            guard !concept.isEmpty else {
                continue
            }

            concepts.insert(concept)
        }

        return concepts.sorted()
    }
}
