import Foundation

public struct RGSIndex: Hashable, Sendable, Codable {
    public let byIdentifier: [String:Int]     // "BLimBanRba" -> node.id
    public let bySortKey: [String:Int]        // "A.F.0104000" -> node.id
    public let labelByGroupKey: [String:String] // groupKey (any level) -> labelShort
    public let byReference: [String:Int]    // in rare cases of referentienummer use
    
    public init(
        byIdentifier: [String:Int],
        bySortKey: [String:Int],    
        labelByGroupKey: [String:String],
        byReference: [String:Int]
    ) {
        self.byIdentifier = byIdentifier
        self.bySortKey = bySortKey
        self.labelByGroupKey = labelByGroupKey
        self.byReference = byReference
    }
}

public extension RGSIndex {
    /// Build index and optionally enrich nodes by resolving parentId/l2Id.
    /// - Parameters:
    ///   - nodes: list of nodes
    ///   - enrichNodes: if true, return nodes with xlsx.links.parentId/l2Id filled where resolvable
    ///   - strict: if true, throw on duplicate sort keys / missing parent references
    /// - Returns: (index, enrichedNodes?)
    static func build(
        from nodes: [RGSNode],
        enrichNodes: Bool = false,
        strict: Bool = false
    ) throws -> (RGSIndex, [RGSNode]?) {
        var byIdentifier: [String:Int] = [:]
        var bySortKey: [String:Int] = [:]
        var labelByKey: [String:String] = [:]   // will also hold prefix labels
        var byReference: [String:Int] = [:]

        // helper to add prefix labels: "A.B.C" -> "A","A.B","A.B.C"
        func addPrefixLabels(for key: String, label: String) {
            guard !key.isEmpty else { return }
            let parts = key.split(separator: ".").map(String.init)
            var prefix = ""
            for i in 0..<parts.count {
                prefix = i == 0 ? parts[0] : prefix + "." + parts[i]
                if labelByKey[prefix] == nil { labelByKey[prefix] = label }
            }
        }

        // First pass: maps
        for n in nodes {
            // identifier -> id (fail on duplicates regardless)
            if byIdentifier.updateValue(n.id, forKey: n.codes.code) != nil {
                throw CompiledChartIndexError.duplicateIdentifier(n.codes.code)
            }

            if let x = n.xlsx {
                let sk = x.cachedSortingKey.trimmingCharacters(in: .whitespacesAndNewlines)

                // skip empty sort keys (common for top-level headings)
                guard !sk.isEmpty else {
                    // still record label for ""? usually not helpful — skip.
                    continue
                }

                // handle duplicate sort keys
                if bySortKey[sk] != nil {
                    if strict {
                        throw CompiledChartIndexError.duplicateSortKey(sk)
                    } else {
                        // non-strict: keep the first mapping (silently). Optionally log:
                        // fputs("warning: duplicate sort key '\(sk)' for node \(n.codes.code) (keeping first)\n", stderr)
                    }
                } else {
                    bySortKey[sk] = n.id
                    addPrefixLabels(for: sk, label: n.labels.short)
                }

                // reference
                if let ref = x.reference, !ref.isEmpty {
                    if byReference.updateValue(n.id, forKey: ref) != nil {
                        if strict { throw CompiledChartIndexError.duplicateReference(ref) }
                        // else: keep first
                    }
                }
            }
        }

        let index = RGSIndex(
            byIdentifier: byIdentifier,
            bySortKey: bySortKey,
            labelByGroupKey: labelByKey,
            byReference: byReference
        )

        guard enrichNodes else { return (index, nil) }

        // Second pass: enrich nodes (fill parentId / l2Id where resolvable)
        var enriched: [RGSNode] = []
        enriched.reserveCapacity(nodes.count)

        for n in nodes {
            guard let x = n.xlsx else {
                enriched.append(n); continue
            }

            var resolvedParentId: Int? = x.links.parentId
            var resolvedL2Id: Int? = x.links.l2Id

            if let pkey = x.links.parentKey, !pkey.isEmpty {
                if let pid = bySortKey[pkey] {
                    resolvedParentId = pid
                } else if strict {
                    throw CompiledChartIndexError.missingParentKey(pkey, for: n.codes.code)
                } else {
                    // leave nil (best-effort)
                }
            }

            let l2key = x.links.l2Key
            if !l2key.isEmpty {
                if let lid = bySortKey[l2key] {
                    resolvedL2Id = lid
                } else if strict {
                    throw CompiledChartIndexError.missingParentKey(l2key, for: n.codes.code)
                }
            }

            // only recreate if something changed
            if resolvedParentId != x.links.parentId || resolvedL2Id != x.links.l2Id {
                let newLinks = RGSNodeLinksXLSXSortingKey(
                    parentKey: x.links.parentKey,
                    l2Key: x.links.l2Key,
                    parentId: resolvedParentId,
                    l2Id: resolvedL2Id
                )
                let newXlsx = RGSNodeXLSXConcept(
                    sortingCode: x.sorting,
                    links: newLinks,
                    filters: x.filters,
                    reference: x.reference
                )
                let newNode = try n.with(xlsx: newXlsx)
                enriched.append(newNode)
            } else {
                enriched.append(n)
            }
        }

        return (index, enriched)
    }
}
