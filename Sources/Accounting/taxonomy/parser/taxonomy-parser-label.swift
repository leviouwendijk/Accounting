import Foundation

public enum TaxonomyLabelParser {
    public static func parse(
        _ xml: String
    ) throws -> [String: String] {
        let document = try XMLDocument(
            xmlString: xml,
            options: [.nodePreserveAll]
        )

        guard let root = document.rootElement() else {
            throw TaxonomyProbeError.parseFailed("missing root element")
        }

        var locatorHrefsByLabel: [String: String] = [:]
        var labelTextByLabel: [String: String] = [:]
        var arcs: [TaxonomyLabelArc] = []

        for element in TaxonomyShared.descendantElements(of: root) {
            let name = element.name ?? ""

            if name.hasSuffix("loc") {
                let label = TaxonomyShared.attributeValue(element, "xlink:label")
                    ?? TaxonomyShared.attributeValue(element, "label")
                    ?? ""
                let href = TaxonomyShared.attributeValue(element, "xlink:href")
                    ?? TaxonomyShared.attributeValue(element, "href")
                    ?? ""

                guard !label.isEmpty, !href.isEmpty else {
                    continue
                }

                locatorHrefsByLabel[label] = href
                continue
            }

            if name.hasSuffix("labelArc") {
                let from = TaxonomyShared.attributeValue(element, "xlink:from")
                    ?? TaxonomyShared.attributeValue(element, "from")
                    ?? ""
                let to = TaxonomyShared.attributeValue(element, "xlink:to")
                    ?? TaxonomyShared.attributeValue(element, "to")
                    ?? ""

                guard !from.isEmpty, !to.isEmpty else {
                    continue
                }

                arcs.append(
                    TaxonomyLabelArc(
                        from: from,
                        to: to
                    )
                )
                continue
            }

            if name.hasSuffix("label") {
                let label = TaxonomyShared.attributeValue(element, "xlink:label")
                    ?? TaxonomyShared.attributeValue(element, "label")
                    ?? ""
                let role = TaxonomyShared.attributeValue(element, "xlink:role")
                    ?? TaxonomyShared.attributeValue(element, "role")
                    ?? ""

                guard !label.isEmpty else {
                    continue
                }

                let isPreferredRole =
                    role.isEmpty
                    || role.lowercased().contains("label")
                    || role.lowercased().contains("standard")

                guard isPreferredRole else {
                    continue
                }

                let text = TaxonomyShared.trim(element.stringValue ?? "")
                guard !text.isEmpty else {
                    continue
                }

                if labelTextByLabel[label] == nil {
                    labelTextByLabel[label] = text
                }
            }
        }

        var labelsByConcept: [String: String] = [:]

        for arc in arcs {
            guard let href = locatorHrefsByLabel[arc.from] else {
                continue
            }

            guard let labelText = labelTextByLabel[arc.to] else {
                continue
            }

            let concept = TaxonomyShared.conceptName(from: href)
            guard !concept.isEmpty else {
                continue
            }

            if labelsByConcept[concept] == nil {
                labelsByConcept[concept] = labelText
            }
        }

        return labelsByConcept
    }
}
