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

            if role.contains("presentationLinkbaseRef") || href.hasSuffix("-pre.xml") {
                refs.presentation.append(ref)
            } else if role.contains("labelLinkbaseRef") || href.hasSuffix("-lab.xml") {
                refs.labels.append(ref)
            } else if role.contains("definitionLinkbaseRef") || href.hasSuffix("-def.xml") {
                refs.definitions.append(ref)
            } else if href.hasSuffix("-tab.xml") {
                refs.tables.append(ref)
            } else {
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
}
