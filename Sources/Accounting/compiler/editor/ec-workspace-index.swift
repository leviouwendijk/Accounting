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

    public let usedEntryIDs: [Int]
    public let usedTransactionIDs: [Int]

    public let entityCompletionItems: [ECCompletionItem]
    public let accountCompletionItems: [ECCompletionItem]
    public let transactionCompletionItems: [ECCompletionItem]
    public let keywordCompletionItems: [ECCompletionItem]

    public let selectGroupCompletionItems: [ECCompletionItem]
    public let entrySortCompletionItems: [ECCompletionItem]
    public let historyEventCompletionItems: [ECCompletionItem]
    public let inventoryMutationCompletionItems: [ECCompletionItem]

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

        self.usedEntryIDs = Array(
            Set(result.resolved.compactMap(\.id))
        ).sorted()

        self.usedTransactionIDs = Array(
            Set(result.transactions.byID.keys.map(\.id))
        ).sorted()

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
                    insertText: Self.shortestEntityInsertText(
                        for: def.key,
                        in: result.entities
                    ),
                    detail: def.effectiveDisplayName,
                    documentation: def.effectiveDetails ?? def.effectiveDisplayName
                )
            }

        // self.entityCompletionItems = result.entities.byFull
        //     .values
        //     .sorted {
        //         $0.key.identifier(displaying: .fullchain)
        //             < $1.key.identifier(displaying: .fullchain)
        //     }
        //     .map { def in
        //         ECCompletionItem(
        //             kind: .entity,
        //             label: def.key.identifier(displaying: .fullchain),
        //             detail: def.effectiveDisplayName,
        //             documentation: def.effectiveDetails ?? def.effectiveDisplayName
        //         )
        //     }

        var accountItems: [ECCompletionItem] = []
        accountItems.reserveCapacity(
            result.accounts.byCode.count + result.accounts.byIdentifier.count
        )

        for (_, node) in result.accounts.byCode.sorted(by: { $0.key < $1.key }) {
            let documentation = [
                node.labels.long == node.labels.short
                    ? nil
                    : node.labels.long,
                node.xlsx?.reference.map { "ref: \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

            accountItems.append(
                ECCompletionItem(
                    kind: .account,
                    label: node.codes.code,
                    detail: node.labels.short,
                    documentation: documentation.isEmpty
                        ? nil
                        : documentation
                )
            )
        }

        for (identifier, node) in result.accounts.byIdentifier.sorted(by: { $0.key < $1.key }) {
            let documentation = [
                node.labels.long == node.labels.short
                    ? nil
                    : node.labels.long,
                node.xlsx?.reference.map { "ref: \($0)" }
            ]
            .compactMap { $0 }
            .joined(separator: "\n")

            accountItems.append(
                ECCompletionItem(
                    kind: .account,
                    label: identifier,
                    detail: "\(node.codes.code) — \(node.labels.short)",
                    documentation: documentation.isEmpty
                        ? nil
                        : documentation
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

        let selectGroups = EntrySelect.normalizedUniqueGroups(
            result.resolved.flatMap { $0.select?.groups ?? [] }
        )

        self.selectGroupCompletionItems = selectGroups.map { group in
            ECCompletionItem(
                kind: .selectGroup,
                label: group,
                detail: "Existing select group"
            )
        }

        self.entrySortCompletionItems = [
            ECCompletionItem(
                kind: .value,
                label: "regular",
                detail: "Entry sort"
            ),
            ECCompletionItem(
                kind: .value,
                label: "adjusting",
                detail: "Entry sort"
            )
        ]

        self.historyEventCompletionItems = [
            ECCompletionItem(
                kind: .keyword,
                label: "recorded",
                detail: "History event"
            ),
            ECCompletionItem(
                kind: .keyword,
                label: "corrected",
                detail: "History event"
            ),
            ECCompletionItem(
                kind: .keyword,
                label: "adjusted",
                detail: "History event"
            )
        ]

        self.inventoryMutationCompletionItems = [
            "add",
            "remove",
            "addition",
            "reduction",
            "adding",
            "removing",
            "rm"
        ].map { value in
            ECCompletionItem(
                kind: .value,
                label: value,
                detail: "Inventory mutation"
            )
        }

        self.keywordCompletionItems = Self.makeCompletionKeywordItems(
            for: .entries
        )
    }

    public func nextEntryIDCompletionItems(
        limit: Int = 3
    ) -> [ECCompletionItem] {
        let start = (usedEntryIDs.last ?? 0) + 1

        return (0..<max(limit, 1)).map { offset in
            let value = start + offset
            return ECCompletionItem(
                kind: .id,
                label: "\(value)",
                detail: offset == 0
                    ? "Suggested next entry id"
                    : "Nearby entry id"
            )
        }
    }

    public func nextTransactionIDCompletionItems(
        limit: Int = 3
    ) -> [ECCompletionItem] {
        let start = (usedTransactionIDs.last ?? 0) + 1

        return (0..<max(limit, 1)).map { offset in
            let value = start + offset
            return ECCompletionItem(
                kind: .id,
                label: "\(value)",
                detail: offset == 0
                    ? "Suggested next transaction id"
                    : "Nearby transaction id"
            )
        }
    }

    public func completionKeywordItems(
        for flavor: EntryCompilerLexingFlavor
    ) -> [ECCompletionItem] {
        switch flavor {
        case .entries:
            return keywordCompletionItems

        default:
            return Self.makeCompletionKeywordItems(
                for: flavor
            )
        }
    }

    private static func makeCompletionKeywordItems(
        for flavor: EntryCompilerLexingFlavor
    ) -> [ECCompletionItem] {
        let sets = aggregateLexingSets(flavor: flavor)

        var values = sets.keywords.union(sets.idents)
        values.formUnion([
            "display",
            "profile",
            "kia"
        ])

        return values
            .sorted()
            .map { value in
                ECCompletionItem(
                    kind: .keyword,
                    label: value
                )
            }
    }

    private static func shortestEntityInsertText(
        for key: EntityKey,
        in entities: EntityStore
    ) -> String {
        let aliasOnly = key.alias.string
        let familyPlusAlias = "\(key.family).\(key.alias.string)"
        let full = key.identifier(displaying: .fullchain)

        let candidates = [
            (
                text: aliasOnly,
                ref: EntityRef(
                    class: nil,
                    family: nil,
                    alias: key.alias
                )
            ),
            (
                text: familyPlusAlias,
                ref: EntityRef(
                    class: nil,
                    family: key.family,
                    alias: key.alias
                )
            ),
            (
                text: full,
                ref: EntityRef(
                    class: key.class,
                    family: key.family,
                    alias: key.alias
                )
            )
        ]

        for candidate in candidates {
            guard resolvesExactly(
                candidate.ref,
                to: key,
                in: entities
            ) else {
                continue
            }

            return candidate.text
        }

        return full
    }

    private static func resolvesExactly(
        _ ref: EntityRef,
        to expected: EntityKey,
        in entities: EntityStore
    ) -> Bool {
        guard let resolved = try? entities.resolve(ref, at: nil) else {
            return false
        }

        return resolved.key == expected
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
