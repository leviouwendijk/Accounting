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
        column: Int
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
        let fieldName = ecFieldNameBeforeCursor(
            analysis: analysis,
            line: line,
            column: column
        )

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

        if let index = analysis.tokenIndex(
            atLine: line,
            column: column
        ) {
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

        let anchor = ecPreviousTokenIndex(
            analysis: analysis,
            line: line,
            column: column
        )

        let previousWord = anchor.flatMap {
            ecPreviousSignificantWord(
                tokens: analysis.tokens,
                before: $0 + 1
            )
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
}
