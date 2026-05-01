import Accounting
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

        for element in TaxonomyShared.descendantElements(of: root) {
            let name = element.name ?? ""
            guard name.hasSuffix("presentationLink") else {
                continue
            }

            let role = TaxonomyShared.attributeValue(element, "xlink:role")
                ?? TaxonomyShared.attributeValue(element, "role")

            var locators: [String: String] = [:]
            var arcs: [TaxonomyPresentationArc] = []

            for node in element.children ?? [] {
                guard let childElement = node as? XMLElement else {
                    continue
                }

                let childName = childElement.name ?? ""

                if childName.hasSuffix("loc") {
                    let label = TaxonomyShared.attributeValue(childElement, "xlink:label")
                        ?? TaxonomyShared.attributeValue(childElement, "label")
                        ?? ""
                    let href = TaxonomyShared.attributeValue(childElement, "xlink:href")
                        ?? TaxonomyShared.attributeValue(childElement, "href")
                        ?? ""

                    guard !label.isEmpty, !href.isEmpty else {
                        continue
                    }

                    locators[label] = href
                    continue
                }

                if childName.hasSuffix("presentationArc") {
                    let from = TaxonomyShared.attributeValue(childElement, "xlink:from")
                        ?? TaxonomyShared.attributeValue(childElement, "from")
                        ?? ""
                    let to = TaxonomyShared.attributeValue(childElement, "xlink:to")
                        ?? TaxonomyShared.attributeValue(childElement, "to")
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
    guard let raw = TaxonomyShared.attributeValue(element, name) else {
        return nil
    }

    return Decimal(string: TaxonomyShared.trim(raw), locale: Locale(identifier: "en_US_POSIX"))
}
