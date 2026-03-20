import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

extension TaxonomyProbe {
    public final class EntrypointParser: NSObject, XMLParserDelegate {
        private(set) var refs = EntrypointRefs()
        private var parseError: Swift.Error?

        public func parse(data: Data) throws -> EntrypointRefs {
            refs = EntrypointRefs()
            parseError = nil

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false

            guard parser.parse() else {
                throw parseError ?? parser.parserError ?? Error.parseFailed("unknown error")
            }

            return refs
        }

        public func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String]
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            guard name == "linkbaseRef" else {
                return
            }

            guard let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                return
            }

            let role = TaxonomyProbe.attributeValue(attributeDict, ["xlink:role", "role"]) ?? ""
            let ref = LinkbaseRef(href: href, role: role)

            switch TaxonomyProbe.classifyLinkbaseRef(ref) {
            case "presentation":
                refs.presentation.append(ref)

            case "label":
                refs.labels.append(ref)

            case "definition":
                refs.definitions.append(ref)

            case "table":
                refs.tables.append(ref)

            case "mapping":
                refs.mappings.append(ref)

            default:
                refs.other.append(ref)
            }
        }

        public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
            self.parseError = parseError
        }
    }

    public final class PresentationParser: NSObject, XMLParserDelegate {
        private(set) var links: [PresentationLink] = []

        private var currentRole: String?
        private var currentLocs: [String: String] = [:]
        private var currentArcs: [PresentationArc] = []
        private var parseError: Swift.Error?

        public func parse(data: Data) throws -> [PresentationLink] {
            links = []
            currentRole = nil
            currentLocs = [:]
            currentArcs = []
            parseError = nil

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false

            guard parser.parse() else {
                throw parseError ?? parser.parserError ?? Error.parseFailed("unknown error")
            }

            return links
        }

        public func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String]
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            switch name {
            case "presentationLink":
                currentRole = TaxonomyProbe.attributeValue(attributeDict, ["xlink:role", "role"]) ?? "(no role)"
                currentLocs = [:]
                currentArcs = []

            case "loc":
                guard currentRole != nil else {
                    return
                }

                guard let label = TaxonomyProbe.attributeValue(attributeDict, ["xlink:label", "label"]),
                      let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                    return
                }

                currentLocs[label] = href

            case "presentationArc":
                guard currentRole != nil else {
                    return
                }

                guard let from = TaxonomyProbe.attributeValue(attributeDict, ["xlink:from", "from"]),
                      let to = TaxonomyProbe.attributeValue(attributeDict, ["xlink:to", "to"]) else {
                    return
                }

                let order = Double(TaxonomyProbe.attributeValue(attributeDict, ["order"]) ?? "0") ?? 0
                currentArcs.append(.init(from: from, to: to, order: order))

            default:
                break
            }
        }

        public func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            guard name == "presentationLink" else {
                return
            }

            if let currentRole {
                links.append(
                    .init(
                        role: currentRole,
                        locs: currentLocs,
                        arcs: currentArcs
                    )
                )
            }

            currentRole = nil
            currentLocs = [:]
            currentArcs = []
        }

        public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
            self.parseError = parseError
        }
    }

    public final class LabelParser: NSObject, XMLParserDelegate {
        private var parseError: Swift.Error?

        private var currentLocs: [String: String] = [:]
        private var currentArcs: [LabelArc] = []
        private var currentResources: [String: String] = [:]

        private var currentResourceLabel: String?
        private var currentResourceRole: String?
        private var currentText = ""

        private(set) var labelsByConcept: [String: String] = [:]

        public func parse(data: Data) throws -> [String: String] {
            parseError = nil
            labelsByConcept = [:]
            currentLocs = [:]
            currentArcs = []
            currentResources = [:]
            currentResourceLabel = nil
            currentResourceRole = nil
            currentText = ""

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false

            guard parser.parse() else {
                throw parseError ?? parser.parserError ?? Error.parseFailed("unknown error")
            }

            return labelsByConcept
        }

        public func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String]
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            switch name {
            case "labelLink":
                currentLocs = [:]
                currentArcs = []
                currentResources = [:]

            case "loc":
                guard let label = TaxonomyProbe.attributeValue(attributeDict, ["xlink:label", "label"]),
                      let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                    return
                }

                currentLocs[label] = href

            case "labelArc":
                guard let from = TaxonomyProbe.attributeValue(attributeDict, ["xlink:from", "from"]),
                      let to = TaxonomyProbe.attributeValue(attributeDict, ["xlink:to", "to"]) else {
                    return
                }

                currentArcs.append(.init(from: from, to: to))

            case "label":
                currentResourceLabel = TaxonomyProbe.attributeValue(attributeDict, ["xlink:label", "label"])
                currentResourceRole = TaxonomyProbe.attributeValue(attributeDict, ["xlink:role", "role"])
                currentText = ""

            default:
                break
            }
        }

        public func parser(_ parser: XMLParser, foundCharacters string: String) {
            if currentResourceLabel != nil {
                currentText.append(string)
            }
        }

        public func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            switch name {
            case "label":
                if let resourceLabel = currentResourceLabel {
                    let text = TaxonomyProbe.trim(currentText)
                    let role = currentResourceRole ?? ""

                    if !text.isEmpty {
                        let isNormalLabel =
                            role.isEmpty ||
                            role.hasSuffix("/label") ||
                            role.contains("label")

                        if isNormalLabel || currentResources[resourceLabel] == nil {
                            currentResources[resourceLabel] = text
                        }
                    }
                }

                currentResourceLabel = nil
                currentResourceRole = nil
                currentText = ""

            case "labelLink":
                for arc in currentArcs {
                    guard let href = currentLocs[arc.from],
                          let labelText = currentResources[arc.to] else {
                        continue
                    }

                    let concept = TaxonomyProbe.conceptName(from: href)
                    if labelsByConcept[concept] == nil {
                        labelsByConcept[concept] = labelText
                    }
                }

                currentLocs = [:]
                currentArcs = []
                currentResources = [:]

            default:
                break
            }
        }

        public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
            self.parseError = parseError
        }
    }

    public final class GenericLinkbaseParser: NSObject, XMLParserDelegate {
        private struct DatapointBuilder {
            var label: String?
            var id: String?
            var role: String?
            var primaryQName: String?
            var dimensions: [RGSExplicitDimension] = []
        }

        private var parseError: Swift.Error?

        private var roleRefs: [RoleRef] = []
        private var arcroleRefs: [ArcroleRef] = []
        private var links: [GenericExtendedLink] = []

        private var currentLinkRole: String?
        private var currentLocators: [String: Locator] = [:]
        private var currentResources: [String: GenericResource] = [:]
        private var currentArcs: [GenericArc] = []

        private var currentDatapoint: DatapointBuilder?

        public func parse(data: Data) throws -> GenericLinkbase {
            parseError = nil
            roleRefs = []
            arcroleRefs = []
            links = []

            currentLinkRole = nil
            currentLocators = [:]
            currentResources = [:]
            currentArcs = []
            currentDatapoint = nil

            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.shouldProcessNamespaces = false
            parser.shouldReportNamespacePrefixes = true
            parser.shouldResolveExternalEntities = false

            guard parser.parse() else {
                throw parseError ?? parser.parserError ?? Error.parseFailed("unknown error")
            }

            return .init(
                roleRefs: roleRefs,
                arcroleRefs: arcroleRefs,
                links: links
            )
        }

        public func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String]
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            switch name {
            case "roleRef":
                guard let roleURI = TaxonomyProbe.attributeValue(attributeDict, ["roleURI"]),
                      let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                    return
                }

                roleRefs.append(.init(roleURI: roleURI, href: href))

            case "arcroleRef":
                guard let arcroleURI = TaxonomyProbe.attributeValue(attributeDict, ["arcroleURI"]),
                      let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                    return
                }

                arcroleRefs.append(.init(arcroleURI: arcroleURI, href: href))

            case "link":
                currentLinkRole = TaxonomyProbe.attributeValue(attributeDict, ["xlink:role", "role"]) ?? "(no role)"
                currentLocators = [:]
                currentResources = [:]
                currentArcs = []

            case "loc":
                guard currentLinkRole != nil else {
                    return
                }

                guard let label = TaxonomyProbe.attributeValue(attributeDict, ["xlink:label", "label"]),
                      let href = TaxonomyProbe.attributeValue(attributeDict, ["xlink:href", "href"]) else {
                    return
                }

                currentLocators[label] = .init(
                    label: label,
                    href: href
                )

            case "datapoint":
                guard currentLinkRole != nil else {
                    return
                }

                currentDatapoint = .init(
                    label: TaxonomyProbe.attributeValue(attributeDict, ["xlink:label", "label"]),
                    id: TaxonomyProbe.attributeValue(attributeDict, ["id"]),
                    role: TaxonomyProbe.attributeValue(attributeDict, ["xlink:role", "role"]),
                    primaryQName: nil,
                    dimensions: []
                )

            case "primary":
                guard currentDatapoint != nil else {
                    return
                }

                let qname = TaxonomyProbe.attributeValue(attributeDict, ["rgs:qname", "qname"])
                currentDatapoint?.primaryQName = qname

            case "explicitDimension":
                guard currentDatapoint != nil else {
                    return
                }

                let qname = TaxonomyProbe.attributeValue(attributeDict, ["rgs:qname", "qname"]) ?? ""
                let member = TaxonomyProbe.attributeValue(attributeDict, ["member"])

                currentDatapoint?.dimensions.append(
                    .init(
                        qname: qname,
                        member: member
                    )
                )

            case "arc":
                guard currentLinkRole != nil else {
                    return
                }

                guard let from = TaxonomyProbe.attributeValue(attributeDict, ["xlink:from", "from"]),
                      let to = TaxonomyProbe.attributeValue(attributeDict, ["xlink:to", "to"]) else {
                    return
                }

                let arcrole = TaxonomyProbe.attributeValue(attributeDict, ["xlink:arcrole", "arcrole"])
                let order = Double(TaxonomyProbe.attributeValue(attributeDict, ["order"]) ?? "")

                currentArcs.append(
                    .init(
                        elementName: name,
                        arcrole: arcrole,
                        from: from,
                        to: to,
                        order: order,
                        attributes: attributeDict
                    )
                )

            default:
                break
            }
        }

        public func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let name = TaxonomyProbe.localName(qName ?? elementName)

            switch name {
            case "datapoint":
                guard let datapoint = currentDatapoint,
                      let label = datapoint.label else {
                    currentDatapoint = nil
                    return
                }

                var attributes: [String: String] = [:]

                if let id = datapoint.id {
                    attributes["id"] = id
                }

                if let role = datapoint.role {
                    attributes["role"] = role
                }

                if let primaryQName = datapoint.primaryQName {
                    attributes["primaryQName"] = primaryQName
                }

                attributes["dimensionCount"] = String(datapoint.dimensions.count)

                for (index, dimension) in datapoint.dimensions.enumerated() {
                    attributes["dimension.\(index).qname"] = dimension.qname
                    if let member = dimension.member {
                        attributes["dimension.\(index).member"] = member
                    }
                }

                currentResources[label] = .init(
                    elementName: "datapoint",
                    label: label,
                    role: datapoint.role,
                    attributes: attributes,
                    text: ""
                )

                currentDatapoint = nil

            case "link":
                if let role = currentLinkRole {
                    links.append(
                        .init(
                            role: role,
                            locators: currentLocators,
                            resources: currentResources,
                            arcs: currentArcs
                        )
                    )
                }

                currentLinkRole = nil
                currentLocators = [:]
                currentResources = [:]
                currentArcs = []
                currentDatapoint = nil

            default:
                break
            }
        }

        public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Swift.Error) {
            self.parseError = parseError
        }
    }

    public static func datapoints(from linkbase: GenericLinkbase) -> [String: RGSDatapoint] {
        var out: [String: RGSDatapoint] = [:]

        for link in linkbase.links {
            for (label, resource) in link.resources {
                guard resource.elementName == "datapoint" else {
                    continue
                }

                let count = Int(resource.attributes["dimensionCount"] ?? "0") ?? 0

                var dimensions: [RGSExplicitDimension] = []
                dimensions.reserveCapacity(count)

                for index in 0..<count {
                    let qname = resource.attributes["dimension.\(index).qname"] ?? ""
                    let member = resource.attributes["dimension.\(index).member"]

                    dimensions.append(
                        .init(
                            qname: qname,
                            member: member
                        )
                    )
                }

                out[label] = .init(
                    label: label,
                    id: resource.attributes["id"],
                    role: resource.role,
                    primaryQName: resource.attributes["primaryQName"],
                    dimensions: dimensions
                )
            }
        }

        return out
    }

    // public static func resolveMappings(from linkbase: GenericLinkbase) -> [ResolvedMapping] {
    //     let datapointsByLabel = datapoints(from: linkbase)
    //     var out: [ResolvedMapping] = []

    //     for link in linkbase.links {
    //         for arc in link.arcs {
    //             guard let locator = link.locators[arc.from],
    //                   let datapoint = datapointsByLabel[arc.to],
    //                   let targetPrimaryQName = datapoint.primaryQName else {
    //                 continue
    //             }

    //             let sourceConcept = conceptName(from: locator.href)

    //             out.append(
    //                 .init(
    //                     sourceLocatorLabel: locator.label,
    //                     sourceHref: locator.href,
    //                     sourceConcept: sourceConcept,
    //                     targetDatapointLabel: datapoint.label,
    //                     targetPrimaryQName: targetPrimaryQName,
    //                     dimensions: datapoint.dimensions,
    //                     order: arc.order
    //                 )
    //             )
    //         }
    //     }

    //     return out.sorted { lhs, rhs in
    //         if lhs.sourceConcept == rhs.sourceConcept {
    //             return lhs.targetPrimaryQName < rhs.targetPrimaryQName
    //         }
    //         return lhs.sourceConcept < rhs.sourceConcept
    //     }
    // }

    public static func appendSample(
        _ value: String,
        to array: inout [String],
        limit: Int = 8
    ) {
        guard !value.isEmpty else {
            return
        }

        guard !array.contains(value) else {
            return
        }

        guard array.count < limit else {
            return
        }

        array.append(value)
    }

    public static func resolveMappingsDetailed(from linkbase: GenericLinkbase) -> MappingResolutionResult {
        let datapointsByLabel = datapoints(from: linkbase)
        var out: [ResolvedMapping] = []
        var diagnostics = MappingResolutionDiagnostics()

        for link in linkbase.links {
            for arc in link.arcs {
                diagnostics.totalArcs += 1

                if let arcrole = arc.arcrole, !arcrole.isEmpty {
                    diagnostics.arcroles[arcrole, default: 0] += 1
                } else {
                    diagnostics.arcroles["(missing)", default: 0] += 1
                }

                guard let locator = link.locators[arc.from] else {
                    diagnostics.droppedMissingLocator += 1
                    appendSample(arc.from, to: &diagnostics.sampleMissingLocatorLabels)
                    continue
                }

                guard let datapoint = datapointsByLabel[arc.to] else {
                    diagnostics.droppedMissingDatapoint += 1
                    appendSample(arc.to, to: &diagnostics.sampleMissingDatapointLabels)
                    continue
                }

                guard let targetPrimaryQName = datapoint.primaryQName,
                      !TaxonomyProbe.trim(targetPrimaryQName).isEmpty else {
                    diagnostics.droppedMissingPrimaryQName += 1
                    appendSample(datapoint.label, to: &diagnostics.sampleMissingPrimaryQNameDatapoints)
                    continue
                }

                let sourceExtraction = conceptNameExtraction(from: locator.href)

                switch sourceExtraction.method {
                case .urlFragment:
                    diagnostics.sourceConceptFromURLFragment += 1

                case .rawHashFragment:
                    diagnostics.sourceConceptFromRawHashFragment += 1

                case .fallbackWholeHref:
                    diagnostics.sourceConceptFromFallbackWholeHref += 1
                    appendSample(locator.href, to: &diagnostics.sampleFallbackSourceHrefs)

                case .emptyHref:
                    diagnostics.sourceConceptFromEmptyHref += 1
                }

                guard let sourceConcept = sourceExtraction.concept,
                      !TaxonomyProbe.trim(sourceConcept).isEmpty else {
                    diagnostics.droppedMissingSourceConcept += 1
                    continue
                }

                out.append(
                    .init(
                        sourceLocatorLabel: locator.label,
                        sourceHref: locator.href,
                        sourceConcept: sourceConcept,
                        targetDatapointLabel: datapoint.label,
                        targetPrimaryQName: targetPrimaryQName,
                        dimensions: datapoint.dimensions,
                        order: arc.order
                    )
                )

                diagnostics.resolvedMappings += 1
            }
        }

        let sorted = out.sorted { lhs, rhs in
            if lhs.sourceConcept == rhs.sourceConcept {
                return lhs.targetPrimaryQName < rhs.targetPrimaryQName
            }
            return lhs.sourceConcept < rhs.sourceConcept
        }

        return .init(
            mappings: sorted,
            diagnostics: diagnostics
        )
    }

    public static func resolveMappings(from linkbase: GenericLinkbase) -> [ResolvedMapping] {
        resolveMappingsDetailed(from: linkbase).mappings
    }
}

extension TaxonomyProbe {
    public static func classifyLinkbaseRef(_ ref: LinkbaseRef) -> String {
        let href = ref.href.lowercased()
        let role = ref.role.lowercased()

        if role.contains("presentationlinkbaseref") || href.hasSuffix("-pre.xml") {
            return "presentation"
        }

        if role.contains("labellinkbaseref") || href.hasSuffix("-lab.xml") {
            return "label"
        }

        if role.contains("definitionlinkbaseref") || href.hasSuffix("-def.xml") {
            return "definition"
        }

        if role.contains("tablelinkbaseref") || href.hasSuffix("-tab.xml") {
            return "table"
        }

        if role.contains("mapping") || href.contains("/mapping/") || href.contains("/map/") || href.contains("map-") {
            return "mapping"
        }

        return "other"
    }
}
