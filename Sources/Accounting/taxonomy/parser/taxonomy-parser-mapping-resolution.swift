import Foundation

extension TaxonomyParser {
    public static func classifyLinkbaseRef(
        _ ref: TaxonomyLinkbaseRef,
        source: TaxonomySourceData
    ) -> TaxonomyLinkbaseKind {
        let href = ref.href.lowercased()
        let role = (ref.role ?? "").lowercased()

        if source.classifyLinkbase(href: href, role: role) == .presentation {
            return .presentation
        }

        if source.classifyLinkbase(href: href, role: role) == .label {
            return .label
        }

        if source.classifyLinkbase(href: href, role: role) == .definition {
            return .definition
        }

        if source.classifyLinkbase(href: href, role: role) == .table {
            return .table
        }

        if source.classifyLinkbase(href: href, role: role) == .mapping {
            return .mapping
        }

        return .other
    }

    // public static func datapoints(
    //     from linkbase: TaxonomyGenericLinkbase
    // ) -> [TaxonomyDatapoint] {
    //     var out: [TaxonomyDatapoint] = []

    //     for link in linkbase.links {
    //         let axisByLocatorLabel = axisConceptsByLocatorLabel(link)
    //         let memberByLocatorLabel = memberConceptsByLocatorLabel(link)
    //         let dimensionBindings = explicitDimensionBindings(
    //             link,
    //             axisByLocatorLabel: axisByLocatorLabel,
    //             memberByLocatorLabel: memberByLocatorLabel
    //         )

    //         for locator in link.locators.values {
    //             let concept = TaxonomyShared.conceptName(from: locator.href)
    //             guard !concept.isEmpty else {
    //                 continue
    //             }

    //             let dimensions = sortDimensions(
    //                 dimensionBindings[locator.label] ?? []
    //             )

    //             out.append(
    //                 TaxonomyDatapoint(
    //                     concept: concept,
    //                     dimensions: dimensions
    //                 )
    //             )
    //         }
    //     }

    //     return out
    // }

    public static func datapoints(
        from linkbase: TaxonomyGenericLinkbase
    ) -> [String: TaxonomyDatapoint] {
        var out: [String: TaxonomyDatapoint] = [:]

        for link in linkbase.links {
            for (label, resource) in link.resources {
                guard resource.elementName == "datapoint" else {
                    continue
                }

                let count = Int(resource.attributes["dimensionCount"] ?? "0") ?? 0

                var dimensions: [TaxonomyExplicitDimension] = []
                dimensions.reserveCapacity(count)

                for index in 0..<count {
                    let qname = resource.attributes["dimension.\(index).qname"] ?? ""
                    let member = resource.attributes["dimension.\(index).member"] ?? ""

                    guard !qname.isEmpty, !member.isEmpty else {
                        continue
                    }

                    dimensions.append(
                        TaxonomyExplicitDimension(
                            axis: qname,
                            member: member
                        )
                    )
                }

                out[label] = TaxonomyDatapoint(
                    label: label,
                    primaryQName: resource.attributes["primaryQName"],
                    dimensions: dimensions
                )
            }
        }

        return out
    }

    public static func appendSample(
        _ value: String,
        to samples: inout [String],
        limit: Int
    ) {
        guard !value.isEmpty else {
            return
        }

        guard !samples.contains(value) else {
            return
        }

        guard samples.count < limit else {
            return
        }

        samples.append(value)

    }

    public static func resolveMappingsDetailed(
        from linkbase: TaxonomyGenericLinkbase
    ) -> TaxonomyMappingResolutionResult {
        let datapoints = datapoints(from: linkbase)

        var resolvedMappings: [TaxonomyResolvedMapping] = []
        var unresolvedSamples: [String] = []
        var totalArcs = 0

        for link in linkbase.links {
            for arc in link.arcs {
                totalArcs += 1

                guard let locator = link.locators[arc.from] else {
                    appendSample(arc.from, to: &unresolvedSamples, limit: 20)
                    continue
                }

                guard let datapoint = datapoints[arc.to] else {
                    appendSample(arc.to, to: &unresolvedSamples, limit: 20)
                    continue
                }

                guard let targetConcept = datapoint.primaryQName,
                      !TaxonomyShared.trim(targetConcept).isEmpty else {
                    appendSample(datapoint.label, to: &unresolvedSamples, limit: 20)
                    continue
                }

                let sourceIdentifier = TaxonomyShared.conceptName(from: locator.href)
                guard !sourceIdentifier.isEmpty else {
                    appendSample(locator.href, to: &unresolvedSamples, limit: 20)
                    continue
                }

                resolvedMappings.append(
                    TaxonomyResolvedMapping(
                        sourceIdentifier: sourceIdentifier,
                        matchedCode: nil,
                        targetConcept: targetConcept,
                        dimensions: datapoint.dimensions
                    )
                )
            }
        }

        let diagnostics = TaxonomyMappingResolutionDiagnostics(
            totalDatapoints: totalArcs,
            resolvedCount: resolvedMappings.count,
            unresolvedCount: totalArcs - resolvedMappings.count,
            unresolvedConceptSamples: unresolvedSamples
        )

        return TaxonomyMappingResolutionResult(
            resolvedMappings: resolvedMappings.sorted {
                if $0.sourceIdentifier == $1.sourceIdentifier {
                    return $0.targetConcept < $1.targetConcept
                }
                return $0.sourceIdentifier < $1.sourceIdentifier
            },
            diagnostics: diagnostics
        )
    }

    // public static func resolveMappingsDetailed(
    //     from linkbase: TaxonomyGenericLinkbase
    // ) -> TaxonomyMappingResolutionResult {
    //     let datapoints = datapoints(from: linkbase)

    //     var resolvedMappings: [TaxonomyResolvedMapping] = []
    //     var unresolvedSamples: [String] = []

    //     for datapoint in datapoints {
    //         let extraction = TaxonomyShared.conceptNameExtraction(from: datapoint.concept)
    //         let sourceIdentifier = extraction.localName

    //         let resolved = TaxonomyResolvedMapping(
    //             sourceIdentifier: sourceIdentifier,
    //             matchedCode: nil,
    //             targetConcept: extraction.localName,
    //             dimensions: datapoint.dimensions
    //         )

    //         resolvedMappings.append(resolved)

    //         if extraction.localName.isEmpty {
    //             appendSample(
    //                 datapoint.concept,
    //                 to: &unresolvedSamples,
    //                 limit: 20
    //             )
    //         }
    //     }

    //     let unresolvedCount = resolvedMappings.reduce(into: 0) { partial, mapping in
    //         if mapping.targetConcept.isEmpty {
    //             partial += 1
    //         }
    //     }

    //     let diagnostics = TaxonomyMappingResolutionDiagnostics(
    //         totalDatapoints: datapoints.count,
    //         resolvedCount: resolvedMappings.count - unresolvedCount,
    //         unresolvedCount: unresolvedCount,
    //         unresolvedConceptSamples: unresolvedSamples
    //     )

    //     return TaxonomyMappingResolutionResult(
    //         resolvedMappings: resolvedMappings,
    //         diagnostics: diagnostics
    //     )
    // }

    public static func resolveMappings(
        from linkbase: TaxonomyGenericLinkbase
    ) -> [TaxonomyResolvedMapping] {
        resolveMappingsDetailed(from: linkbase).resolvedMappings
    }
}

private extension TaxonomyParser {
    static func axisConceptsByLocatorLabel(
        _ link: TaxonomyGenericExtendedLink
    ) -> [String: String] {
        var out: [String: String] = [:]

        for locator in link.locators.values {
            let concept = TaxonomyShared.conceptName(from: locator.href)
            guard !concept.isEmpty else {
                continue
            }

            if concept.lowercased().contains("axis") {
                out[locator.label] = concept
            }
        }

        return out
    }

    static func memberConceptsByLocatorLabel(
        _ link: TaxonomyGenericExtendedLink
    ) -> [String: String] {
        var out: [String: String] = [:]

        for locator in link.locators.values {
            let concept = TaxonomyShared.conceptName(from: locator.href)
            guard !concept.isEmpty else {
                continue
            }

            if concept.lowercased().contains("member") {
                out[locator.label] = concept
            }
        }

        return out
    }

    static func explicitDimensionBindings(
        _ link: TaxonomyGenericExtendedLink,
        axisByLocatorLabel: [String: String],
        memberByLocatorLabel: [String: String]
    ) -> [String: [TaxonomyExplicitDimension]] {
        var out: [String: [TaxonomyExplicitDimension]] = [:]

        for arc in link.arcs {
            guard let arcrole = arc.arcrole?.lowercased() else {
                continue
            }

            let isDimensionDomain =
                arcrole.contains("dimension-domain")
                || arcrole.contains("dimensiondomain")

            let isDomainMember =
                arcrole.contains("domain-member")
                || arcrole.contains("domainmember")

            if isDimensionDomain {
                guard let axis = axisByLocatorLabel[arc.from] else {
                    continue
                }

                guard let member = memberByLocatorLabel[arc.to]
                    ?? conceptNameIfMember(link.locators[arc.to]?.href)
                else {
                    continue
                }

                out[arc.to, default: []].append(
                    TaxonomyExplicitDimension(
                        axis: axis,
                        member: member
                    )
                )
            }

            if isDomainMember {
                guard let inherited = out[arc.from], !inherited.isEmpty else {
                    continue
                }

                out[arc.to, default: []].append(contentsOf: inherited)
            }
        }

        return out
    }

    static func conceptNameIfMember(
        _ href: String?
    ) -> String? {
        guard let href else {
            return nil
        }

        let concept = TaxonomyShared.conceptName(from: href)
        guard concept.lowercased().contains("member") else {
            return nil
        }

        return concept
    }

    static func sortDimensions(
        _ dimensions: [TaxonomyExplicitDimension]
    ) -> [TaxonomyExplicitDimension] {
        dimensions.sorted {
            if $0.axis == $1.axis {
                return $0.member < $1.member
            }

            return $0.axis < $1.axis
        }
    }
}
