import Foundation

public enum TaxonomyPresentationParser {
    public static func parse(
        _ xml: String
    ) throws -> [TaxonomyPresentationLink] {
        let document = try XMLDocument(
            xmlString: xml,
            options: [.nodePreserveAll]
        )

        guard let root = document.rootElement() else {
            throw TaxonomyProbeError.parseFailed("missing root element")
        }

        var links: [TaxonomyPresentationLink] = []

        for element in descendantElements(of: root) {
            let name = element.name ?? ""
            guard name.hasSuffix("presentationLink") else {
                continue
            }

            let role = attributeValue(element, "xlink:role")
                ?? attributeValue(element, "role")

            var locators: [String: String] = [:]
            var arcs: [TaxonomyPresentationArc] = []

            for node in element.children ?? [] {
                guard let childElement = node as? XMLElement else {
                    continue
                }

                let childName = childElement.name ?? ""

                if childName.hasSuffix("loc") {
                    let label = attributeValue(childElement, "xlink:label")
                        ?? attributeValue(childElement, "label")
                        ?? ""
                    let href = attributeValue(childElement, "xlink:href")
                        ?? attributeValue(childElement, "href")
                        ?? ""

                    guard !label.isEmpty, !href.isEmpty else {
                        continue
                    }

                    locators[label] = href
                    continue
                }

                if childName.hasSuffix("presentationArc") {
                    let from = attributeValue(childElement, "xlink:from")
                        ?? attributeValue(childElement, "from")
                        ?? ""
                    let to = attributeValue(childElement, "xlink:to")
                        ?? attributeValue(childElement, "to")
                        ?? ""

                    guard !from.isEmpty, !to.isEmpty else {
                        continue
                    }

                    let order = decimalAttributeValue(
                        childElement,
                        "order"
                    )

                    arcs.append(
                        TaxonomyPresentationArc(
                            parent: from,
                            child: to,
                            order: order
                        )
                    )
                }
            }

            links.append(
                TaxonomyPresentationLink(
                    role: role,
                    locators: locators,
                    arcs: arcs
                )
            )
        }

        return links
    }
}

private func decimalAttributeValue(
    _ element: XMLElement,
    _ name: String
) -> Decimal? {
    guard let raw = attributeValue(element, name) else {
        return nil
    }

    return Decimal(string: trim(raw), locale: Locale(identifier: "en_US_POSIX"))
}
