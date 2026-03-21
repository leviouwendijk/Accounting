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

        for element in TaxonomyShared.descendantElements(of: root) {
            let name = element.name ?? ""
            let local = TaxonomyShared.localName(name)

            if local == "roleRef" {
                let roleURI = TaxonomyShared.attributeValue(element, "roleURI") ?? ""
                let href = TaxonomyShared.attributeValue(element, "xlink:href")
                    ?? TaxonomyShared.attributeValue(element, "href")
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
                let arcroleURI = TaxonomyShared.attributeValue(element, "arcroleURI") ?? ""
                let href = TaxonomyShared.attributeValue(element, "xlink:href")
                    ?? TaxonomyShared.attributeValue(element, "href")
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
        let role = TaxonomyShared.attributeValue(element, "xlink:role")
            ?? TaxonomyShared.attributeValue(element, "role")
        let type = TaxonomyShared.localName(element.name ?? "")

        var locators: [String: TaxonomyLocator] = [:]
        var resources: [String: TaxonomyGenericResource] = [:]
        var arcs: [TaxonomyGenericArc] = []

        for node in element.children ?? [] {
            guard let child = node as? XMLElement else {
                continue
            }

            let childLocalName = TaxonomyShared.localName(child.name ?? "")

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
        let label = TaxonomyShared.attributeValue(element, "xlink:label")
            ?? TaxonomyShared.attributeValue(element, "label")
            ?? ""
        let href = TaxonomyShared.attributeValue(element, "xlink:href")
            ?? TaxonomyShared.attributeValue(element, "href")
            ?? ""

        return TaxonomyLocator(
            label: label,
            href: href
        )
    }

    static func parseResource(
        _ element: XMLElement
    ) -> TaxonomyGenericResource {
        let label = TaxonomyShared.attributeValue(element, "xlink:label")
            ?? TaxonomyShared.attributeValue(element, "label")
            ?? ""
        let role = TaxonomyShared.attributeValue(element, "xlink:role")
            ?? TaxonomyShared.attributeValue(element, "role")
        let text = TaxonomyShared.trim(element.stringValue ?? "")

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
        let arcrole = TaxonomyShared.attributeValue(element, "xlink:arcrole")
            ?? TaxonomyShared.attributeValue(element, "arcrole")
        let from = TaxonomyShared.attributeValue(element, "xlink:from")
            ?? TaxonomyShared.attributeValue(element, "from")
            ?? ""
        let to = TaxonomyShared.attributeValue(element, "xlink:to")
            ?? TaxonomyShared.attributeValue(element, "to")
            ?? ""
        let targetRole = TaxonomyShared.attributeValue(element, "xlink:targetRole")
            ?? TaxonomyShared.attributeValue(element, "targetRole")

        let order: Decimal?
        if let rawOrder = TaxonomyShared.attributeValue(element, "order") {
            order = Decimal(
                string: TaxonomyShared.trim(rawOrder),
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
