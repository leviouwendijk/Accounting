import Foundation

private enum ECCompletionContext {
    case entityReference
    case accountReference
    case transactionReference
    case keyword
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
        case .entityReference:
            return workspace.entityCompletionItems

        case .accountReference:
            return workspace.accountCompletionItems

        case .transactionReference:
            return workspace.transactionCompletionItems

        case .keyword:
            return workspace.keywordCompletionItems
        }
    }
}

private extension ECEditorService {
    static func completionContext(
        analysis: ECDocumentAnalysis,
        line: Int,
        column: Int
    ) -> ECCompletionContext {
        if let index = analysis.tokenIndex(atLine: line, column: column) {
            let token = analysis.tokens[index]

            switch token {
            case .entity:
                return .entityReference

            case .account:
                return .accountReference

            case .number:
                if isTransactionReference(tokens: analysis.tokens, at: index) {
                    return .transactionReference
                }

            default:
                break
            }
        }

        guard let index = previousTokenIndex(
            analysis: analysis,
            line: line,
            column: column
        ) else {
            return .keyword
        }

        if let previousKeyword = previousSignificantKeyword(
            tokens: analysis.tokens,
            before: index + 1
        ) {
            switch previousKeyword {
            case "for":
                return .entityReference

            case "in":
                return .accountReference

            case "ref":
                return .transactionReference

            default:
                break
            }
        }

        return .keyword
    }

    static func previousTokenIndex(
        analysis: ECDocumentAnalysis,
        line: Int,
        column: Int
    ) -> Int? {
        var best: Int?
        var bestLine = Int.min
        var bestColumn = Int.min

        for (index, span) in analysis.spans.enumerated() {
            let startsBeforeCursor =
                span.start.line < line
                || (span.start.line == line && span.start.column <= column)

            guard startsBeforeCursor else {
                continue
            }

            if span.start.line > bestLine
                || (span.start.line == bestLine && span.start.column > bestColumn) {
                best = index
                bestLine = span.start.line
                bestColumn = span.start.column
            }
        }

        return best
    }

    static func previousSignificantKeyword(
        tokens: [EntryCompilerToken],
        before index: Int
    ) -> String? {
        guard index > 0 else {
            return nil
        }

        var i = index - 1
        while i >= 0 {
            switch tokens[i] {
            case .lPar,
                 .rPar,
                 .lBrace,
                 .rBrace,
                 .comma,
                 .dot,
                 .equals,
                 .arrow,
                 .hash:
                break

            case .keyword(let s):
                return s

            case .ident(let s):
                return s

            default:
                return nil
            }

            if i == 0 {
                break
            }

            i -= 1
        }

        return nil
    }
}
