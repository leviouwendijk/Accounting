import Foundation

public struct RGSAssemblerResult: Sendable {
    public let totalsById: [Int: Decimal]
    public let kindById: [Int: StatementKind]    // .balance or .income
    public let sortKeyById: [Int: String]        // "A.B.A010" etc.
    public let directionById: [Int: Direction]   // debit | credit
    public let parentById: [Int: Int]            // child -> parent
}

public struct StatementBundle: Sendable {
    public let balance: [RGSPresentationLine]
    public let income:  [RGSPresentationLine]
    public let totalsById: [Int: Decimal]   // for debugging / future use
    
    public init(
        balance: [RGSPresentationLine],
        income: [RGSPresentationLine],
        totalsById: [Int: Decimal]   // for debugging / future use
    ) {
        self.balance = balance
        self.income = income
        self.totalsById = totalsById
    }
}

public enum RGSAssembler {
    public static func assemble(
        chart: CompiledChart,
        trialRows: [TrialBalanceRow],
        cut: AssembleCut,
        omslag: OmslagMode
    ) throws -> StatementBundle {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let index = ch.index else { throw NSError(domain: "RGSAssembler", code: 1, userInfo: [NSLocalizedDescriptionKey:"Missing index"]) }

        // Build maps + fallbacks
        let maps   = try RGSAssembler.makeMaps(from: ch)

        // Seed + roll-up
        let seed   = RGSAssembler.seedLeafs(from: trialRows, using: index)
        let totals = RGSAssembler.rollupAmounts(seed, parentById: maps.parentById)

        // Forced inclusions (codes → ids)
        let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = cut.includeIntermediates
            ? Set(forcedIds.flatMap { chainToRoot($0, parentById: maps.parentById) })
            : forcedIds

        // Labels by sort-key prefix
        let labels = index.labelByGroupKey

        // Build lines
        let bs = linesFor(.balance, roll: maps, totals: totals, labels: labels,
                          cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)
        let is_ = linesFor(.income,  roll: maps, totals: totals, labels: labels,
                          cut: cut, forcedIds: forcedIds, forcedChain: forcedChain, omslag: omslag)

        return StatementBundle(balance: bs, income: is_, totalsById: totals)
    }


    // public static func makeMaps(from chart: CompiledChart) throws -> RGSAssemblerResult {
    //     let ch = try chart.ensuringIndex(enrichNodes: true, strict: false) // fills parentId/l2Id
    //     var kindById: [Int: StatementKind] = [:]
    //     var sortKeyById: [Int: String] = [:]
    //     var directionById: [Int: Direction] = [:]
    //     var parentById: [Int: Int] = [:]

    //     for n in ch.nodes {
    //         if let x = n.xlsx {
    //             sortKeyById[n.id] = x.cachedSortingKey
    //             if let pid = x.links.parentId { parentById[n.id] = pid }
    //         }
    //         directionById[n.id] = n.direction
    //         // B* => balance, W* => income
    //         if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
    //         else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }
    //     }

    //     return .init(totalsById: [:],
    //                  kindById: kindById,
    //                  sortKeyById: sortKeyById,
    //                  directionById: directionById,
    //                  parentById: parentById)
    // }

    public static func makeMaps(from chart: CompiledChart) throws -> RGSAssemblerResult {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        guard let idx = ch.index else { fatalError("index missing") }

        var kindById: [Int: StatementKind] = [:]
        var sortKeyById: [Int: String] = [:]
        var directionById: [Int: Direction] = [:]
        var parentById: [Int: Int] = [:]

        for n in ch.nodes {
            guard let x = n.xlsx else { continue }
            let key = x.cachedSortingKey
            sortKeyById[n.id] = key
            directionById[n.id] = n.direction
            if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
            else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }

            // primary: use enriched parentId
            if let pid = x.links.parentId {
                parentById[n.id] = pid
            } else {
                // fallback: derive from sort-key prefix
                if let pkey = RGSNodeSortingCode(key: key).parentKeyString,
                   let pid = idx.bySortKey[pkey] {
                    parentById[n.id] = pid
                }
            }
        }

        return .init(
            totalsById: [:],
            kindById: kindById,
            sortKeyById: sortKeyById,
            directionById: directionById,
            parentById: parentById
        )
    }

    public static func seedLeafs(from trial: [TrialBalanceRow],
                                 using index: RGSIndex) -> [Int: Decimal] {
        var byId: [Int: Decimal] = [:]
        for row in trial {
            if let id = index.byIdentifier[row.accountCode] {
                byId[id, default: 0] += row.net
            }
        }
        return byId
    }

    // public static func rollupAmounts(
    //     _ seed: [Int: Decimal],
    //     parentById: [Int: Int]
    // ) -> [Int: Decimal] {
    //     var totals = seed
    //     // single pass repeated until stable or use stack of ancestors:
    //     // Build children map once:
    //     var children: [Int: [Int]] = [:]
    //     for (child, parent) in parentById { children[parent, default: []].append(child) }

    //     // Post-order DFS
    //     func dfs(_ id: Int) -> Decimal {
    //         var sum = totals[id] ?? 0
    //         for c in children[id] ?? [] { sum += dfs(c) }
    //         totals[id] = sum
    //         return sum
    //     }
    //     // Roots = ids that aren't someone’s child
    //     let allIds = Set(parentById.keys).union(Set(parentById.values))
    //     let childSet = Set(parentById.keys)
    //     let roots = Array(allIds.subtracting(childSet))
    //     for r in roots { _ = dfs(r) }
    //     return totals
    // }

    public static func rollupAmounts(
        _ seed: [Int: Decimal],
        parentById: [Int: Int]
    ) -> [Int: Decimal] {
        var totals = seed
        for (leaf, amt) in seed where amt != 0 {
            var cur = leaf
            while let p = parentById[cur] {
                totals[p, default: 0] += amt
                cur = p
            }
        }
        return totals
    }

    public static func present(
        _ amount: Decimal,
        direction: Direction,
        mode: OmslagMode = .apply
    ) -> Decimal {
        guard mode == .apply else { return amount }
        switch direction {
        case .debit:  return amount
        case .credit: return -amount
        }
    }
}
