import Foundation

public enum TaxonomyGenericLinkbaseParser {
    public static func parse(
        _ xml: String
    ) throws -> TaxonomyGenericLinkbase {
        let document = try XMLDocument(
            xmlString: xml,
            options: [.nodePreserveAll]
        )

        guard let root = document.rootElement() else {
            throw TaxonomyProbeError.parseFailed("missing root element")
        }

        var roleRefs: [TaxonomyRoleRef] = []
        var arcroleRefs: [TaxonomyArcroleRef] = []
        var links: [TaxonomyGenericExtendedLink] = []

        for element in descendantElements(of: root) {
            let name = element.name ?? ""
            let local = localName(name)

            if local == "roleRef" {
                let roleURI = attributeValue(element, "roleURI") ?? ""
                let href = attributeValue(element, "xlink:href")
                    ?? attributeValue(element, "href")
                    ?? ""

                guard !roleURI.isEmpty, !href.isEmpty else {
                    continue
                }

                roleRefs.append(
                    TaxonomyRoleRef(
                        roleURI: roleURI,
                        href: href
                    )
                )
                continue
            }

            if local == "arcroleRef" {
                let arcroleURI = attributeValue(element, "arcroleURI") ?? ""
                let href = attributeValue(element, "xlink:href")
                    ?? attributeValue(element, "href")
                    ?? ""

                guard !arcroleURI.isEmpty, !href.isEmpty else {
                    continue
                }

                arcroleRefs.append(
                    TaxonomyArcroleRef(
                        arcroleURI: arcroleURI,
                        href: href
                    )
                )
                continue
            }

            guard local.hasSuffix("Link") else {
                continue
            }

            links.append(parseExtendedLink(element))
        }

        return TaxonomyGenericLinkbase(
            roleRefs: roleRefs,
            arcroleRefs: arcroleRefs,
            links: links
        )
    }
}

private extension TaxonomyGenericLinkbaseParser {
    static func parseExtendedLink(
        _ element: XMLElement
    ) -> TaxonomyGenericExtendedLink {
        let role = attributeValue(element, "xlink:role")
            ?? attributeValue(element, "role")
        let type = localName(element.name ?? "")

        var locators: [String: TaxonomyLocator] = [:]
        var resources: [String: TaxonomyGenericResource] = [:]
        var arcs: [TaxonomyGenericArc] = []

        for node in element.children ?? [] {
            guard let child = node as? XMLElement else {
                continue
            }

            let childLocalName = localName(child.name ?? "")

            if childLocalName == "loc" {
                let locator = parseLocator(child)
                if !locator.label.isEmpty {
                    locators[locator.label] = locator
                }
                continue
            }

            if childLocalName.hasSuffix("Arc") {
                arcs.append(parseArc(child))
                continue
            }

            let resource = parseResource(child)
            if !resource.label.isEmpty {
                resources[resource.label] = resource
            }
        }

        return TaxonomyGenericExtendedLink(
            role: role,
            type: type,
            locators: locators,
            resources: resources,
            arcs: arcs
        )
    }

    static func parseLocator(
        _ element: XMLElement
    ) -> TaxonomyLocator {
        let label = attributeValue(element, "xlink:label")
            ?? attributeValue(element, "label")
            ?? ""
        let href = attributeValue(element, "xlink:href")
            ?? attributeValue(element, "href")
            ?? ""

        return TaxonomyLocator(
            label: label,
            href: href
        )
    }

    static func parseResource(
        _ element: XMLElement
    ) -> TaxonomyGenericResource {
        let label = attributeValue(element, "xlink:label")
            ?? attributeValue(element, "label")
            ?? ""
        let role = attributeValue(element, "xlink:role")
            ?? attributeValue(element, "role")
        let text = trim(element.stringValue ?? "")

        var attributes: [String: String] = [:]
        for attribute in element.attributes ?? [] {
            guard let name = attribute.name else {
                continue
            }

            attributes[name] = attribute.stringValue ?? ""
        }

        return TaxonomyGenericResource(
            label: label,
            role: role,
            text: text,
            attributes: attributes
        )
    }

    static func parseArc(
        _ element: XMLElement
    ) -> TaxonomyGenericArc {
        let arcrole = attributeValue(element, "xlink:arcrole")
            ?? attributeValue(element, "arcrole")
        let from = attributeValue(element, "xlink:from")
            ?? attributeValue(element, "from")
            ?? ""
        let to = attributeValue(element, "xlink:to")
            ?? attributeValue(element, "to")
            ?? ""
        let targetRole = attributeValue(element, "xlink:targetRole")
            ?? attributeValue(element, "targetRole")

        let order: Decimal?
        if let rawOrder = attributeValue(element, "order") {
            order = Decimal(
                string: trim(rawOrder),
                locale: Locale(identifier: "en_US_POSIX")
            )
        } else {
            order = nil
        }

        var attributes: [String: String] = [:]
        for attribute in element.attributes ?? [] {
            guard let name = attribute.name else {
                continue
            }

            attributes[name] = attribute.stringValue ?? ""
        }

        return TaxonomyGenericArc(
            arcrole: arcrole,
            from: from,
            to: to,
            order: order,
            targetRole: targetRole,
            attributes: attributes
        )
    }
}
