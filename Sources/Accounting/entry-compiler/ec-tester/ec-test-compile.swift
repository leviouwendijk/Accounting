import Foundation

@inline(__always)
private func makeEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return enc
}

@inline(__always)
private func ensureDir(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

@inline(__always)
private func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let data = try makeEncoder().encode(value)
    try data.write(to: url, options: .atomic)
}

public struct TrialBalanceRow: Codable, Sendable {
    public let accountCode: String
    public let debit: Decimal
    public let credit: Decimal
    public var net: Decimal { debit - credit }
}

public func trialBalance(_ entries: [ResolvedEntry]) -> [TrialBalanceRow] {
    var deb: [String: Decimal] = [:]
    var cre: [String: Decimal] = [:]
    for e in entries {
        for l in e.lines {
            let code = l.account.code
            if l.direction == .debit {
                deb[code, default: 0] += l.amount
            } else {
                cre[code, default: 0] += l.amount
            }
        }
    }
    let codes = Set(deb.keys).union(cre.keys).sorted()
    return codes.map { c in
        TrialBalanceRow(accountCode: c,
                        debit: deb[c] ?? 0,
                        credit: cre[c] ?? 0)
    }
}

/// End-to-end compile + snapshots into <projectRoot>/test/_snapshots
/// Uses the new store shapes (byFull/byCode/byID) and TransactionKey in resolved entries.
public func ecTestCompile(
    projectRoot: URL,
    snapshotsDirName: String = "_snapshots"
) throws {
    // Compile the project (this also asserts balanced entries)
    let result = try EntryCompileDriver.compile(projectRoot: projectRoot)

    // Where to write snapshots
    let outDir = projectRoot.appendingPathComponent("test", isDirectory: true)
        .appendingPathComponent(snapshotsDirName, isDirectory: true)
    try ensureDir(outDir)

    // ---------- Entities snapshot ----------
    struct EntitiesSnapshot: Codable {
        struct Item: Codable {
            let key: String
            let displayName: String?
        }
        let items: [Item]
    }

    let entItems: [EntitiesSnapshot.Item] =
        result.entities.byFull.values
            .map { def in
                let ident = def.key.identifier(displaying: EntityKey.AliasType.fullchain)
                return EntitiesSnapshot.Item(key: ident, displayName: def.displayName)
            }
            .sorted { $0.key < $1.key }

    try writeJSON(EntitiesSnapshot(items: entItems),
                  to: outDir.appendingPathComponent("entities.json"))

    // ---------- Accounts snapshot ----------
    struct AccountsSnapshot: Codable {
        struct Item: Codable {
            let code: String
            let label: String
            let direction: Direction
            let level: Int
        }
        let items: [Item]
    }

    let accItems: [AccountsSnapshot.Item] =
        result.accounts.byCode.values
            .sorted { $0.code < $1.code }
            .map { a in
                AccountsSnapshot.Item(code: a.code,
                                      label: a.label,
                                      direction: a.direction,
                                      level: a.level)
            }

    try writeJSON(AccountsSnapshot(items: accItems),
                  to: outDir.appendingPathComponent("accounts.json"))

    // ---------- Transactions snapshot ----------
    struct TransactionsSnapshot: Codable {
        struct Item: Codable {
            let id: Int
            let source: TransactionSource
            let status: TransactionStatus
            let description: String?
        }
        let items: [Item]
    }

    // Keep ids deterministic by using keys from byID
    let txItems: [TransactionsSnapshot.Item] =
        result.transactions.byID
            .map { (k, t) in (k.id, t) }
            .sorted { $0.0 < $1.0 }
            .map { (id, t) in
                TransactionsSnapshot.Item(id: id,
                                          source: t.source,
                                          status: t.status,
                                          description: t.details)
            }

    try writeJSON(TransactionsSnapshot(items: txItems),
                  to: outDir.appendingPathComponent("transactions.json"))

    // ---------- Trial balance snapshot ----------
    let tb = trialBalance(result.resolved)
    try writeJSON(tb, to: outDir.appendingPathComponent("trial-balance.json"))

    // ---------- Resolved entries snapshot (optional, helpful) ----------
    try writeJSON(result.resolved, to: outDir.appendingPathComponent("resolved-entries.json"))

    // ---------- Statements snapshots ----------
    do {
        // 3a) choose plans (tweak partition/materiality/previous as you like)
        let planBS = AggregationPlan(
            statement: StatementLibrary.balanceIFRS(materiality: 1000),
            partition: .init(keys: [.entity], requireBalanced: true),
            filters: [],
            includePreviousPeriods: true
        )
        let planIS = AggregationPlan(
            statement: StatementLibrary.incomeStatementIFRS(materiality: 0),
            partition: nil,
            filters: [],
            includePreviousPeriods: true
        )
        let planCF = AggregationPlan(
            statement: StatementLibrary.cashSimple(materiality: 0),
            partition: nil,
            filters: [],
            includePreviousPeriods: false
        )
        let planEQ = AggregationPlan(
            statement: StatementLibrary.equityView(materiality: 0),
            partition: .init(keys: [.entityClass], requireBalanced: false),
            filters: [],
            includePreviousPeriods: false
        )

        // 3b) run the aggregator for each plan
        let aggr = Aggregator(accounts: result.accounts, plan: planBS)
        let cubeBS = try aggr.buildCube(entries: result.resolved, previousEntries: [])
        try writeJSON(snapshotDTO(cube: cubeBS, statement: planBS.statement),
                      to: outDir.appendingPathComponent("statement.balance.json"))

        do {
            let cubeIS = try Aggregator(accounts: result.accounts, plan: planIS)
                .buildCube(entries: result.resolved, previousEntries: [])
            try writeJSON(snapshotDTO(cube: cubeIS, statement: planIS.statement),
                          to: outDir.appendingPathComponent("statement.income.json"))
        }

        do {
            let cubeCF = try Aggregator(accounts: result.accounts, plan: planCF)
                .buildCube(entries: result.resolved)
            try writeJSON(snapshotDTO(cube: cubeCF, statement: planCF.statement),
                          to: outDir.appendingPathComponent("statement.cash.json"))
        }

        do {
            let cubeEQ = try Aggregator(accounts: result.accounts, plan: planEQ)
                .buildCube(entries: result.resolved)
            try writeJSON(snapshotDTO(cube: cubeEQ, statement: planEQ.statement),
                          to: outDir.appendingPathComponent("statement.equity.json"))
        }

        vprint(true, "  ✓ statements (balance/income/cash/equity)")
    }
}
