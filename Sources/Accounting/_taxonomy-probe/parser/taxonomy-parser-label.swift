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

        for element in descendantElements(of: root) {
            let name = element.name ?? ""

            if name.hasSuffix("loc") {
                let label = attributeValue(element, "xlink:label")
                    ?? attributeValue(element, "label")
                    ?? ""
                let href = attributeValue(element, "xlink:href")
                    ?? attributeValue(element, "href")
                    ?? ""

                guard !label.isEmpty, !href.isEmpty else {
                    continue
                }

                locatorHrefsByLabel[label] = href
                continue
            }

            if name.hasSuffix("labelArc") {
                let from = attributeValue(element, "xlink:from")
                    ?? attributeValue(element, "from")
                    ?? ""
                let to = attributeValue(element, "xlink:to")
                    ?? attributeValue(element, "to")
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
                let label = attributeValue(element, "xlink:label")
                    ?? attributeValue(element, "label")
                    ?? ""
                let role = attributeValue(element, "xlink:role")
                    ?? attributeValue(element, "role")
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

                let text = trim(element.stringValue ?? "")
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

            let concept = conceptName(from: href)
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
