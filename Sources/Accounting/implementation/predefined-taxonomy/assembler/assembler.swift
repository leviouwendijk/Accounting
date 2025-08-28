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
        target: TargetLevel,
        omslag: OmslagMode
    ) throws -> StatementBundle {
        // 1) Ensure index + parent links available
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false)
        let index = ch.index!                           // you just ensured it
        // 2) Build maps once
        let maps = try RGSAssembler.makeMaps(from: ch)  // your renamed makeMaps
        // 3) Seed + roll up
        let seed   = RGSAssembler.seedLeafs(from: trialRows, using: index)
        let totals = RGSAssembler.rollupAmounts(seed, parentById: maps.parentById)
        // 4) Labels for group keys
        let labels = index.labelByGroupKey
        // 5) Build lines
        let bs = linesFor(.balance, roll: maps, totals: totals, labels: labels, target: target, omslag: omslag)
        let is_ = linesFor(.income,  roll: maps, totals: totals, labels: labels, target: target, omslag: omslag)
        return StatementBundle(balance: bs, income: is_, totalsById: totals)
    }


    // 1) Build maps from the compiled chart
    public static func makeMaps(from chart: CompiledChart) throws -> RGSAssemblerResult {
        let ch = try chart.ensuringIndex(enrichNodes: true, strict: false) // fills parentId/l2Id
        var kindById: [Int: StatementKind] = [:]
        var sortKeyById: [Int: String] = [:]
        var directionById: [Int: Direction] = [:]
        var parentById: [Int: Int] = [:]

        for n in ch.nodes {
            if let x = n.xlsx {
                sortKeyById[n.id] = x.cachedSortingKey
                if let pid = x.links.parentId { parentById[n.id] = pid }
            }
            directionById[n.id] = n.direction
            // B* => balance, W* => income
            if n.codes.code.hasPrefix("B") { kindById[n.id] = .balance }
            else if n.codes.code.hasPrefix("W") { kindById[n.id] = .income }
        }

        return .init(totalsById: [:],
                     kindById: kindById,
                     sortKeyById: sortKeyById,
                     directionById: directionById,
                     parentById: parentById)
    }

    // 2) Seed leaf amounts from trial rows (account code → id)
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

    // 3) Bottom-up roll-up over parents
    public static func rollupAmounts(_ seed: [Int: Decimal],
                                     parentById: [Int: Int]) -> [Int: Decimal] {
        var totals = seed
        // single pass repeated until stable or use stack of ancestors:
        // Build children map once:
        var children: [Int: [Int]] = [:]
        for (child, parent) in parentById { children[parent, default: []].append(child) }

        // Post-order DFS
        func dfs(_ id: Int) -> Decimal {
            var sum = totals[id] ?? 0
            for c in children[id] ?? [] { sum += dfs(c) }
            totals[id] = sum
            return sum
        }
        // Roots = ids that aren't someone’s child
        let allIds = Set(parentById.keys).union(Set(parentById.values))
        let childSet = Set(parentById.keys)
        let roots = Array(allIds.subtracting(childSet))
        for r in roots { _ = dfs(r) }
        return totals
    }

    // 4) Presentation “omslag”: debit stays +, credit shown as +
    public static func present(_ amount: Decimal,
                               direction: Direction,
                               mode: OmslagMode = .apply) -> Decimal {
        guard mode == .apply else { return amount }
        switch direction {
        case .debit:  return amount
        case .credit: return -amount
        }
    }
}
