import Foundation

private enum ECCompletionContext {
    case none
    case entityReference
    case accountReference
    case transactionReference
    case entryID
    case transactionID
    case selectGroup
    case sortValue
    case dateExpression
    case dateLiteralValue
    case dateInferValue
    case dateBlockField
    case dateYearValue
    case dateMonthValue
    case dateDayValue
    case historyEvent
    case inventoryMutation
    case keyword
    case selectKeyword
    case transactionsKeyword
}

public extension ECEditorService {
    static func completions(
        analysis: ECDocumentAnalysis,
        workspace: ECWorkspaceIndex,
        line: Int,
        column: Int,
        documentFilePath: String? = nil
    ) -> [ECCompletionItem] {
        let context = completionContext(
            analysis: analysis,
            line: line,
            column: column
        )

        switch context {
        case .none:
            return []

        case .entityReference:
            return workspace.entityCompletionItems

        case .accountReference:
            return workspace.accountCompletionItems

        case .transactionReference:
            return workspace.transactionCompletionItems

        case .entryID:
            return workspace.nextEntryIDCompletionItems()

        case .transactionID:
            return workspace.nextTransactionIDCompletionItems()

        case .selectGroup:
            return workspace.selectGroupCompletionItems

        case .sortValue:
            return workspace.entrySortCompletionItems

        case .dateExpression:
            return makeDateExpressionCompletionItems(
                documentFilePath: documentFilePath
            )

        case .dateLiteralValue:
            return makeDateLiteralCompletionItems(
                documentFilePath: documentFilePath
            )

        case .dateInferValue:
            return makeDateInferCompletionItems(
                documentFilePath: documentFilePath
            )

        case .dateBlockField:
            return makeDateBlockFieldCompletionItems(
                documentFilePath: documentFilePath
            )

        case .dateYearValue:
            return makeDateComponentCompletionItems(
                component: .year,
                documentFilePath: documentFilePath
            )

        case .dateMonthValue:
            return makeDateComponentCompletionItems(
                component: .month,
                documentFilePath: documentFilePath
            )

        case .dateDayValue:
            return makeDateComponentCompletionItems(
                component: .day,
                documentFilePath: documentFilePath
            )

        case .historyEvent:
            return workspace.historyEventCompletionItems

        case .inventoryMutation:
            return workspace.inventoryMutationCompletionItems

        case .selectKeyword:
            return [
                ECCompletionItem(
                    kind: .keyword,
                    label: "group",
                    detail: "Select group"
                )
            ]

        case .transactionsKeyword:
            return [
                ECCompletionItem(
                    kind: .keyword,
                    label: "ref",
                    detail: "Transaction reference"
                )
            ]

        case .keyword:
            return workspace.completionKeywordItems(
                for: analysis.flavor
            )
        }
    }
}

private extension ECEditorService {
    static func completionContext(
        analysis: ECDocumentAnalysis,
        line: Int,
        column: Int
    ) -> ECCompletionContext {
        let stack = ecBlockStack(
            analysis: analysis,
            line: line,
            column: column
        )

        if stack.contains(.details) || stack.contains(.display) {
            return .none
        }

        if stack.contains(.metadata) {
            return .none
        }

        let topBlock = stack.last

        let tokenIndexAtCursor = analysis.tokenIndex(
            atLine: line,
            column: column
        )

        let previousTokenIndex = ecPreviousTokenIndex(
            analysis: analysis,
            line: line,
            column: column
        )

        let previousWords: [String] = {
            if let tokenIndexAtCursor {
                return ecPreviousSignificantWords(
                    tokens: analysis.tokens,
                    before: tokenIndexAtCursor,
                    limit: 2
                )
            }

            guard let previousTokenIndex else {
                return []
            }

            switch analysis.tokens[previousTokenIndex] {
            case .keyword(let s),
                 .ident(let s):
                switch s {
                case "date",
                     "infer",
                     "sort",
                     "group",
                     "ref",
                     "for",
                     "in":
                    return ecPreviousSignificantWords(
                        tokens: analysis.tokens,
                        before: previousTokenIndex + 1,
                        limit: 2
                    )

                default:
                    return ecPreviousSignificantWords(
                        tokens: analysis.tokens,
                        before: previousTokenIndex,
                        limit: 2
                    )
                }

            default:
                return ecPreviousSignificantWords(
                    tokens: analysis.tokens,
                    before: previousTokenIndex,
                    limit: 2
                )
            }
        }()

        let previousWord = previousWords.first
        let secondPreviousWord = previousWords.dropFirst().first

        if previousWord == "infer", secondPreviousWord == "date" {
            return .dateInferValue
        }

        if previousWord == "date" {
            return .dateExpression
        }

        if previousWord == "sort" {
            return .sortValue
        }

        let fieldName = ecFieldNameBeforeCursor(
            analysis: analysis,
            line: line,
            column: column
        )

        if stack.contains(.date) {
            if let fieldName {
                switch fieldName {
                case "year":
                    return .dateYearValue

                case "month":
                    return .dateMonthValue

                case "day":
                    return .dateDayValue

                default:
                    break
                }
            }

            return .dateBlockField
        }

        if let fieldName {
            switch fieldName {
            case "id":
                switch topBlock {
                case .entry:
                    return .entryID

                case .transaction:
                    return .transactionID

                default:
                    break
                }

            case "date":
                return .dateLiteralValue

            case "account":
                return .accountReference

            case "entity":
                return .entityReference

            case "group":
                if topBlock == .select {
                    return .selectGroup
                }

            case "sort":
                return .sortValue

            case "mutation":
                if stack.contains(.inventory) {
                    return .inventoryMutation
                }

            default:
                break
            }
        }

        if let index = tokenIndexAtCursor {
            let token = analysis.tokens[index]

            switch token {
            case .entity:
                return .entityReference

            case .account:
                return .accountReference

            case .number:
                if isTransactionReference(
                    tokens: analysis.tokens,
                    at: index
                ) {
                    return .transactionReference
                }

            default:
                break
            }
        }

        if topBlock == .history {
            return .historyEvent
        }

        if topBlock == .select {
            if previousWord == "group" {
                return .selectGroup
            }

            return .selectKeyword
        }

        if topBlock == .transactions {
            if previousWord == "ref" {
                return .transactionReference
            }

            return .transactionsKeyword
        }

        switch previousWord {
        case "for":
            return .entityReference

        case "in":
            return .accountReference

        case "ref":
            return .transactionReference

        case "group":
            if topBlock == .select {
                return .selectGroup
            }

        case "sort":
            return .sortValue

        default:
            break
        }

        return .keyword
    }

    static func makeDateExpressionCompletionItems(
        documentFilePath: String?
    ) -> [ECCompletionItem] {
        let candidates = ecSuggestedDates(
            documentFilePath: documentFilePath
        )

        var items: [ECCompletionItem] = []

        for candidate in candidates {
            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "infer \(candidate.day)",
                    detail: "\(candidate.source) — \(candidate.iso8601)"
                )
            )

            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "= \(candidate.iso8601)",
                    detail: candidate.source
                )
            )
        }

        if let first = candidates.first {
            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "{ year/month/day }",
                    insertText:
"""
{
    year = \(first.year)
    month = \(first.month)
    day = \(first.day)
}
""",
                    detail: "Date block from \(first.source.lowercased())"
                )
            )
        }

        return ecDedupeCompletionItemsByLabel(items)
    }

    static func makeDateLiteralCompletionItems(
        documentFilePath: String?
    ) -> [ECCompletionItem] {
        ecSuggestedDates(
            documentFilePath: documentFilePath
        ).map { candidate in
            ECCompletionItem(
                kind: .value,
                label: candidate.iso8601,
                detail: candidate.source
            )
        }
    }

    static func makeDateInferCompletionItems(
        documentFilePath: String?
    ) -> [ECCompletionItem] {
        ecSuggestedDates(
            documentFilePath: documentFilePath
        ).map { candidate in
            ECCompletionItem(
                kind: .value,
                label: "\(candidate.day)",
                detail: "\(candidate.source) — \(candidate.iso8601)"
            )
        }
    }

    static func makeDateBlockFieldCompletionItems(
        documentFilePath: String?
    ) -> [ECCompletionItem] {
        let candidates = ecSuggestedDates(
            documentFilePath: documentFilePath
        )

        var items: [ECCompletionItem] = []

        for candidate in candidates {
            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "year = \(candidate.year)",
                    detail: candidate.source
                )
            )

            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "month = \(candidate.month)",
                    detail: candidate.source
                )
            )

            items.append(
                ECCompletionItem(
                    kind: .value,
                    label: "day = \(candidate.day)",
                    detail: candidate.source
                )
            )
        }

        return ecDedupeCompletionItemsByLabel(items)
    }

    static func makeDateComponentCompletionItems(
        component: ECDateComponent,
        documentFilePath: String?
    ) -> [ECCompletionItem] {
        ecSuggestedDates(
            documentFilePath: documentFilePath
        ).map { candidate in
            let value: Int

            switch component {
            case .year:
                value = candidate.year

            case .month:
                value = candidate.month

            case .day:
                value = candidate.day
            }

            return ECCompletionItem(
                kind: .value,
                label: "\(value)",
                detail: "\(candidate.source) — \(candidate.iso8601)"
            )
        }
    }
}

private enum ECDateComponent {
    case year
    case month
    case day
}

private struct ECSuggestedDate: Hashable {
    let year: Int
    let month: Int
    let day: Int
    let source: String

    var iso8601: String {
        String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
}

private func ecPreviousSignificantWords(
    tokens: [EntryCompilerToken],
    before index: Int,
    limit: Int
) -> [String] {
    guard limit > 0 else {
        return []
    }

    var out: [String] = []
    var cursor = index

    while out.count < limit,
          let i = ecPreviousSignificantIndex(
              tokens: tokens,
              before: cursor
          ) {
        switch tokens[i] {
        case .keyword(let s),
             .ident(let s):
            out.append(s)

        default:
            break
        }

        cursor = i
    }

    return out
}

private func ecSuggestedDates(
    documentFilePath: String?,
    now: Date = Date()
) -> [ECSuggestedDate] {
    var out: [ECSuggestedDate] = []

    if let inferred = ecSuggestedDateFromFilePath(
        documentFilePath
    ) {
        out.append(inferred)
    }

    out.append(
        ecTodaySuggestedDate(now: now)
    )

    var seen = Set<String>()

    return out.filter { candidate in
        seen.insert(candidate.iso8601).inserted
    }
}

private func ecSuggestedDateFromFilePath(
    _ filePath: String?
) -> ECSuggestedDate? {
    guard let filePath else {
        return nil
    }

    let components = URL(fileURLWithPath: filePath)
        .standardizedFileURL
        .pathComponents

    if let index = components.lastIndex(of: "entries"),
       components.count > index + 3,
       let year = Int(components[index + 1]),
       let month = Int(components[index + 2]),
       let day = Int(components[index + 3]) {
        return ECSuggestedDate(
            year: year,
            month: month,
            day: day,
            source: "From document path"
        )
    }

    if let index = components.lastIndex(of: "transactions"),
       components.count > index + 3,
       let year = Int(components[index + 1]),
       let month = Int(components[index + 2]) {
        let rawDay = (components[index + 3] as NSString)
            .deletingPathExtension

        if let day = Int(rawDay) {
            return ECSuggestedDate(
                year: year,
                month: month,
                day: day,
                source: "From document path"
            )
        }
    }

    return nil
}

private func ecTodaySuggestedDate(
    now: Date
) -> ECSuggestedDate {
    let calendar = Calendar.current
    let comps = calendar.dateComponents(
        [.year, .month, .day],
        from: now
    )

    return ECSuggestedDate(
        year: comps.year ?? 1970,
        month: comps.month ?? 1,
        day: comps.day ?? 1,
        source: "Today"
    )
}

private func ecDedupeCompletionItemsByLabel(
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
