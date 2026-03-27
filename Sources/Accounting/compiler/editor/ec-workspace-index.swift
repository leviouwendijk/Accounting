import Foundation

public struct ECWorkspaceIndex: Sendable {
    public let entities: EntityStore
    public let accounts: AccountStore
    public let transactions: TransactionStore
    public let resolvedEntries: [ResolvedEntry]

    public let chartDefinition: ECDefinitionResult
    public let entityDefinitionByKey: [EntityKey: ECDefinitionResult]
    public let accountDefinitionByCode: [String: ECDefinitionResult]
    public let accountDefinitionByIdentifier: [String: ECDefinitionResult]
    public let transactionDefinitionByID: [Int: ECDefinitionResult]
    public let entryDefinitionByID: [Int: ECDefinitionResult]

    public let entityCompletionItems: [ECCompletionItem]
    public let accountCompletionItems: [ECCompletionItem]
    public let transactionCompletionItems: [ECCompletionItem]
    public let keywordCompletionItems: [ECCompletionItem]

    public init(
        result: EntryCompileDriver.Result,
        chartDefinition: ECDefinitionResult
    ) {
        self.entities = result.entities
        self.accounts = result.accounts
        self.transactions = result.transactions
        self.resolvedEntries = result.resolved
        self.chartDefinition = chartDefinition

        var entityDefs: [EntityKey: ECDefinitionResult] = [:]
        for (key, def) in result.entities.byFull {
            guard
                let loc = def.location,
                let file = loc.file
            else {
                continue
            }

            entityDefs[key] = ECDefinitionResult(
                file: file,
                line: loc.line,
                column: loc.column
            )
        }

        var accountDefsByCode: [String: ECDefinitionResult] = [:]
        for (code, _) in result.accounts.byCode {
            accountDefsByCode[code] = chartDefinition
        }

        var accountDefsByIdentifier: [String: ECDefinitionResult] = [:]
        for (identifier, node) in result.accounts.byIdentifier {
            accountDefsByIdentifier[identifier] =
                accountDefsByCode[node.codes.code]
                ?? chartDefinition
        }

        var transactionDefs: [Int: ECDefinitionResult] = [:]
        var entryDefs: [Int: ECDefinitionResult] = [:]

        for entry in result.resolved {
            if let id = entry.id,
               let loc = entry.location,
               let file = loc.file {
                entryDefs[id] = ECDefinitionResult(
                    file: file,
                    line: loc.line,
                    column: loc.column
                )
            }

            guard
                let loc = entry.location,
                let file = loc.file
            else {
                continue
            }

            for tx in entry.transactionReferences {
                transactionDefs[tx.id] = ECDefinitionResult(
                    file: file,
                    line: loc.line,
                    column: loc.column
                )
            }
        }

        self.entityDefinitionByKey = entityDefs
        self.accountDefinitionByCode = accountDefsByCode
        self.accountDefinitionByIdentifier = accountDefsByIdentifier
        self.transactionDefinitionByID = transactionDefs
        self.entryDefinitionByID = entryDefs

        self.entityCompletionItems = result.entities.byFull
            .values
            .sorted {
                $0.key.identifier(displaying: .fullchain)
                    < $1.key.identifier(displaying: .fullchain)
            }
            .map { def in
                ECCompletionItem(
                    kind: .entity,
                    label: def.key.identifier(displaying: .fullchain),
                    detail: def.displayName,
                    documentation: def.metadata["details"] ?? def.displayName
                )
            }

        var accountItems: [ECCompletionItem] = []
        accountItems.reserveCapacity(
            result.accounts.byCode.count + result.accounts.byIdentifier.count
        )

        for (_, node) in result.accounts.byCode.sorted(by: { $0.key < $1.key }) {
            accountItems.append(
                ECCompletionItem(
                    kind: .account,
                    label: node.codes.code,
                    detail: node.labels.short,
                    documentation: node.xlsx?.reference
                )
            )
        }

        for (identifier, node) in result.accounts.byIdentifier.sorted(by: { $0.key < $1.key }) {
            accountItems.append(
                ECCompletionItem(
                    kind: .account,
                    label: identifier,
                    detail: "\(node.codes.code) — \(node.labels.short)",
                    documentation: node.xlsx?.reference
                )
            )
        }

        self.accountCompletionItems = dedupeCompletionItems(accountItems)

        self.transactionCompletionItems = result.transactions.byID.keys
            .sorted { $0.id < $1.id }
            .map { key in
                let tx = result.transactions.byID[key]
                return ECCompletionItem(
                    kind: .transaction,
                    label: "\(key.id)",
                    detail: tx?.details,
                    documentation: tx?.source.rawValue
                )
            }

        self.keywordCompletionItems = [
            "entry",
            "for",
            "in",
            "ref",
            "details",
            "metadata",
            "display_name",
            "entity",
            "use",
            "alias",
            "variant",
            "subvariant",
            "unit",
            "trait",
            "profile",
            "depreciation",
            "kia"
        ].map {
            ECCompletionItem(
                kind: .keyword,
                label: $0
            )
        }
    }

    public static func build(
        projectRoot: URL,
        verbose: Bool = false
    ) throws -> ECWorkspaceIndex {
        let project = EntryCompilerProject(root: projectRoot)
        let settings = try EntryCompilerSettingsLoader.load(
            from: projectRoot,
            trace: true
        )

        let chartURL = project.resource(
            finding: settings.aggregation.chartFind,
            version: settings.aggregation.chartVersion
        )

        let chartDefinition = ECDefinitionResult(
            file: chartURL.path,
            line: 1,
            column: 1
        )

        let result = try EntryCompileDriver.compile(
            projectRoot: projectRoot,
            setting: .init(
                entities: true,
                accounts: true,
                transactions: true,
                entries: true,
                assertion: false,
                loc_trace: true
            ),
            verbose: verbose
        )

        return ECWorkspaceIndex(
            result: result,
            chartDefinition: chartDefinition
        )
    }
}

private func dedupeCompletionItems(
    _ items: [ECCompletionItem]
) -> [ECCompletionItem] {
    var seen = Set<String>()
    var out: [ECCompletionItem] = []
    out.reserveCapacity(items.count)

    for item in items {
        if seen.insert(item.label).inserted {
            out.append(item)
        }
    }

    return out
}
