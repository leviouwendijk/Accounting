import Foundation

public enum TaxonomyEntrypointParser {
    public static func parse(
        _ xml: String,
        source: TaxonomySourceData
    ) throws -> TaxonomyEntrypointRefs {
        let document = try XMLDocument(
            xmlString: xml,
            options: [.nodePreserveAll]
        )

        guard let root = document.rootElement() else {
            throw TaxonomyProbeError.parseFailed("missing root element")
        }

        var presentation: [TaxonomyLinkbaseRef] = []
        var labels: [TaxonomyLinkbaseRef] = []
        var definitions: [TaxonomyLinkbaseRef] = []
        var tables: [TaxonomyLinkbaseRef] = []
        var mappings: [TaxonomyLinkbaseRef] = []
        var other: [TaxonomyLinkbaseRef] = []

        for element in TaxonomyShared.descendantElements(of: root) {
            let name = element.name ?? ""
            guard name.hasSuffix("linkbaseRef") else {
                continue
            }

            let href = TaxonomyShared.attributeValue(element, "xlink:href")
                ?? TaxonomyShared.attributeValue(element, "href")
                ?? ""

            guard !href.isEmpty else {
                continue
            }

            let role = TaxonomyShared.attributeValue(element, "xlink:role")
                ?? TaxonomyShared.attributeValue(element, "role")

            let ref = TaxonomyLinkbaseRef(
                href: href,
                role: role
            )

            switch TaxonomyParser.classifyLinkbaseRef(ref, source: source) {
            case .presentation:
                presentation.append(ref)

            case .label:
                labels.append(ref)

            case .definition:
                definitions.append(ref)

            case .table:
                tables.append(ref)

            case .mapping:
                mappings.append(ref)

            case .other:
                other.append(ref)
            }
        }

        return TaxonomyEntrypointRefs(
            presentation: presentation,
            labels: labels,
            definitions: definitions,
            tables: tables,
            mappings: mappings,
            other: other
        )
    }
}
