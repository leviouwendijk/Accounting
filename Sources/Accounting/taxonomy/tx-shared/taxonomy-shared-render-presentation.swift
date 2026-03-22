import Foundation

extension TaxonomyShared {
    public static func renderPresentationLink(
        _ link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: TaxonomyComputedFact],
        pruneEmpty: Bool = false
    ) {
        let orderedChildrenByParent = orderedChildrenByParent(link)
        let childConcepts = Set(link.arcs.map(\.child))
        let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

        let normalizedFactsByConcept = Dictionary(
            uniqueKeysWithValues: factsByConcept.map { key, value in
                (
                    normalizedTaxonomyConceptKey(key),
                    value
                )
            }
        )

        print("presentation:")

        if rootConcepts.isEmpty {
            print("  no roots")
            return
        }

        var renderedAnyRoot = false

        for root in rootConcepts {
            if pruneEmpty,
               !shouldRenderPresentationNode(
                    locatorLabel: root,
                    link: link,
                    orderedChildrenByParent: orderedChildrenByParent,
                    flattenedFactsByConcept: normalizedFactsByConcept
               ) {
                continue
            }

            renderedAnyRoot = true

            var visited = Set<String>()

            renderPresentationNode(
                locatorLabel: root,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: normalizedFactsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                pruneEmpty: pruneEmpty,
                indent: 0,
                visited: &visited
            )
        }

        if !renderedAnyRoot {
            print("  no populated roots")
        }
    }

    public static func renderPresentationLink(
        _ link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        source: TaxonomySourceData,
        pruneEmpty: Bool = false
    ) {
        let orderedChildrenByParent = orderedChildrenByParent(link)
        let childConcepts = Set(link.arcs.map(\.child))
        let rootConcepts = link.locators.keys.filter { !childConcepts.contains($0) }.sorted()

        let normalizedFactsByConcept = Dictionary(
            uniqueKeysWithValues: factsByConcept.map { key, value in
                (
                    normalizedTaxonomyConceptKey(key),
                    value
                )
            }
        )

        print("presentation:")

        if rootConcepts.isEmpty {
            print("  no roots")
            return
        }

        var renderedAnyRoot = false

        for root in rootConcepts {
            if pruneEmpty,
               !shouldRenderPresentationNode(
                    locatorLabel: root,
                    link: link,
                    orderedChildrenByParent: orderedChildrenByParent,
                    dimensionalFactsByConcept: normalizedFactsByConcept
               ) {
                continue
            }

            renderedAnyRoot = true

            var visited = Set<String>()

            renderPresentationNode(
                locatorLabel: root,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: normalizedFactsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                source: source,
                pruneEmpty: pruneEmpty,
                indent: 0,
                visited: &visited
            )
        }

        if !renderedAnyRoot {
            print("  no populated roots")
        }
    }
}

private extension TaxonomyShared {
    static func orderedChildrenByParent(
        _ link: TaxonomyPresentationLink
    ) -> [String: [TaxonomyPresentationArc]] {
        let grouped = Dictionary(grouping: link.arcs, by: \.parent)

        var out: [String: [TaxonomyPresentationArc]] = [:]
        for (parent, arcs) in grouped {
            out[parent] = arcs.sorted { lhs, rhs in
                switch (lhs.order, rhs.order) {
                case let (l?, r?):
                    if l == r {
                        return lhs.child < rhs.child
                    }

                    return l < r

                case (.some, .none):
                    return true

                case (.none, .some):
                    return false

                case (.none, .none):
                    return lhs.child < rhs.child
                }
            }
        }

        return out
    }

    static func normalizedPresentationConcept(
        locatorLabel: String,
        link: TaxonomyPresentationLink
    ) -> String? {
        guard let href = link.locators[locatorLabel] else {
            return nil
        }

        return conceptNameExtraction(from: href).normalizedName
    }

    static func displayPresentationConcept(
        locatorLabel: String,
        link: TaxonomyPresentationLink
    ) -> String? {
        guard let href = link.locators[locatorLabel] else {
            return nil
        }

        return conceptNameExtraction(from: href).localName
    }

    static func shouldRenderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        flattenedFactsByConcept: [String: TaxonomyComputedFact]
    ) -> Bool {
        if let concept = normalizedPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ),
        flattenedFactsByConcept[concept] != nil {
            return true
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            if shouldRenderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                flattenedFactsByConcept: flattenedFactsByConcept
            ) {
                return true
            }
        }

        return false
    }

    static func shouldRenderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        dimensionalFactsByConcept: [String: [TaxonomyComputedMappedFact]]
    ) -> Bool {
        if let concept = normalizedPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ),
        let facts = dimensionalFactsByConcept[concept],
        !facts.isEmpty {
            return true
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            if shouldRenderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                dimensionalFactsByConcept: dimensionalFactsByConcept
            ) {
                return true
            }
        }

        return false
    }

    static func renderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: TaxonomyComputedFact],
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        pruneEmpty: Bool,
        indent: Int,
        visited: inout Set<String>
    ) {
        guard !visited.contains(locatorLabel) else {
            return
        }

        if pruneEmpty,
           !shouldRenderPresentationNode(
                locatorLabel: locatorLabel,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                flattenedFactsByConcept: factsByConcept
           ) {
            return
        }

        visited.insert(locatorLabel)

        guard let normalizedConcept = normalizedPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ) else {
            return
        }

        let displayConcept = displayPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ) ?? normalizedConcept

        let label = labelsByConcept[displayConcept] ?? displayConcept
        let prefix = String(repeating: "    ", count: indent)

        if let fact = factsByConcept[normalizedConcept] {
            print("\(prefix)\(label) = \(decimalString(fact.amount))")
        } else {
            print("\(prefix)\(label)")
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            renderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                pruneEmpty: pruneEmpty,
                indent: indent + 1,
                visited: &visited
            )
        }
    }

    static func renderPresentationNode(
        locatorLabel: String,
        link: TaxonomyPresentationLink,
        labelsByConcept: [String: String],
        factsByConcept: [String: [TaxonomyComputedMappedFact]],
        orderedChildrenByParent: [String: [TaxonomyPresentationArc]],
        source: TaxonomySourceData,
        pruneEmpty: Bool,
        indent: Int,
        visited: inout Set<String>
    ) {
        guard !visited.contains(locatorLabel) else {
            return
        }

        if pruneEmpty,
           !shouldRenderPresentationNode(
                locatorLabel: locatorLabel,
                link: link,
                orderedChildrenByParent: orderedChildrenByParent,
                dimensionalFactsByConcept: factsByConcept
           ) {
            return
        }

        visited.insert(locatorLabel)

        guard let normalizedConcept = normalizedPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ) else {
            return
        }

        let displayConcept = displayPresentationConcept(
            locatorLabel: locatorLabel,
            link: link
        ) ?? normalizedConcept

        let label = labelsByConcept[displayConcept] ?? displayConcept
        let prefix = String(repeating: "    ", count: indent)

        if let facts = factsByConcept[normalizedConcept], !facts.isEmpty {
            let total = facts.reduce(Decimal.zero) { partial, fact in
                partial + fact.amount
            }

            if let summary = summarizedPresentationDimensions(facts, source: source) {
                print("\(prefix)\(label) = \(decimalString(total)) :: \(summary)")
            } else {
                print("\(prefix)\(label) = \(decimalString(total))")
            }
        } else {
            print("\(prefix)\(label)")
        }

        for arc in orderedChildrenByParent[locatorLabel] ?? [] {
            renderPresentationNode(
                locatorLabel: arc.child,
                link: link,
                labelsByConcept: labelsByConcept,
                factsByConcept: factsByConcept,
                orderedChildrenByParent: orderedChildrenByParent,
                source: source,
                pruneEmpty: pruneEmpty,
                indent: indent + 1,
                visited: &visited
            )
        }
    }
}
