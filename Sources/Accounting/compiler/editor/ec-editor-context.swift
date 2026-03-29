import Foundation

enum ECEditorBlockKind: String, Sendable {
    case anonymous
    case entry
    case transaction
    case date
    case display
    case details
    case metadata
    case history
    case select
    case transactions
    case inventory
    case groupedFor
    case groupedIn
    case line
    case posting
}

enum ECDocumentIDNamespace: String, Sendable {
    case entry
    case transaction
}

struct ECDocumentIDOccurrence: Sendable, Hashable {
    let namespace: ECDocumentIDNamespace
    let id: Int
    let span: SourceSpan
}

enum ECEditorParenContext: Sendable {
    case generic
    case forEntity
    case forAccount
}

@inline(__always)
func ecStartsBeforeOrAt(
    _ span: SourceSpan,
    line: Int,
    column: Int
) -> Bool {
    span.start.line < line
        || (span.start.line == line && span.start.column <= column)
}

func ecPreviousTokenIndex(
    analysis: ECDocumentAnalysis,
    line: Int,
    column: Int
) -> Int? {
    var best: Int?
    var bestLine = Int.min
    var bestColumn = Int.min

    for (index, span) in analysis.spans.enumerated() {
        guard ecStartsBeforeOrAt(span, line: line, column: column) else {
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

func ecPreviousSignificantIndex(
    tokens: [EntryCompilerToken],
    before index: Int
) -> Int? {
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

        case .keyword,
             .ident:
            return i

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

func ecPreviousSignificantWord(
    tokens: [EntryCompilerToken],
    before index: Int
) -> String? {
    guard let i = ecPreviousSignificantIndex(
        tokens: tokens,
        before: index
    ) else {
        return nil
    }

    switch tokens[i] {
    case .keyword(let s),
         .ident(let s):
        return s

    default:
        return nil
    }
}

func ecGroupedClauseBlockKindBeforeBrace(
    tokens: [EntryCompilerToken],
    before index: Int
) -> ECEditorBlockKind? {
    guard index > 0 else {
        return nil
    }

    var parenDepth = 0
    var clauseWords: [String] = []
    var i = index - 1

    while true {
        switch tokens[i] {
        case .rPar:
            parenDepth += 1

        case .lPar:
            if parenDepth > 0 {
                parenDepth -= 1
            }

        case .lBrace,
             .rBrace:
            if parenDepth == 0 {
                switch clauseWords {
                case ["for"]:
                    return .groupedFor

                case ["in"]:
                    return .groupedIn

                default:
                    return nil
                }
            }

        case .keyword(let s),
             .ident(let s):
            if parenDepth == 0, s == "for" || s == "in" {
                clauseWords.append(s)
            }

        default:
            break
        }

        if i == 0 {
            break
        }

        i -= 1
    }

    switch clauseWords {
    case ["for"]:
        return .groupedFor

    case ["in"]:
        return .groupedIn

    default:
        return nil
    }
}

func ecBlockKindIntroduced(
    tokens: [EntryCompilerToken],
    before index: Int
) -> ECEditorBlockKind? {
    if let grouped = ecGroupedClauseBlockKindBeforeBrace(
        tokens: tokens,
        before: index
    ) {
        return grouped
    }

    guard let word = ecPreviousSignificantWord(
        tokens: tokens,
        before: index
    ) else {
        return nil
    }

    switch word {
    case "entry":
        return .entry

    case "date":
        return .date

    case "transaction":
        return .transaction

    case "display":
        return .display

    case "details":
        return .details

    case "metadata":
        return .metadata

    case "history":
        return .history

    case "select":
        return .select

    case "transactions":
        return .transactions

    case "inventory":
        return .inventory

    case "line":
        return .line

    case "posting":
        return .posting

    default:
        return nil
    }
}

func ecBlockStack(
    analysis: ECDocumentAnalysis,
    line: Int,
    column: Int
) -> [ECEditorBlockKind] {
    var stack: [ECEditorBlockKind] = []

    for (index, token) in analysis.tokens.enumerated() {
        let span = analysis.spans[index]

        guard ecStartsBeforeOrAt(span, line: line, column: column) else {
            break
        }

        switch token {
        case .lBrace:
            stack.append(
                ecBlockKindIntroduced(
                    tokens: analysis.tokens,
                    before: index
                ) ?? .anonymous
            )

        case .rBrace:
            if !stack.isEmpty {
                stack.removeLast()
            }

        default:
            break
        }
    }

    return stack
}

func ecParenContext(
    analysis: ECDocumentAnalysis,
    line: Int,
    column: Int
) -> ECEditorParenContext? {
    var stack: [ECEditorParenContext] = []
    var pending: ECEditorParenContext?

    for (index, token) in analysis.tokens.enumerated() {
        let span = analysis.spans[index]

        guard ecStartsBeforeOrAt(span, line: line, column: column) else {
            break
        }

        switch token {
        case .keyword("for"),
             .ident("for"):
            pending = .forEntity

        case .keyword("in"),
             .ident("in"):
            pending = .forAccount

        case .keyword,
             .ident:
            pending = nil

        case .lPar:
            stack.append(
                pending
                ?? stack.last
                ?? .generic
            )
            pending = nil

        case .rPar:
            if !stack.isEmpty {
                stack.removeLast()
            }
            pending = nil

        default:
            break
        }
    }

    return stack.last
}

func ecFieldNameBeforeCursor(
    analysis: ECDocumentAnalysis,
    line: Int,
    column: Int
) -> String? {
    let anchor: Int

    if let tokenIndex = analysis.tokenIndex(
        atLine: line,
        column: column
    ) {
        anchor = tokenIndex
    } else if let prevIndex = ecPreviousTokenIndex(
        analysis: analysis,
        line: line,
        column: column
    ) {
        anchor = prevIndex
    } else {
        return nil
    }

    var i = anchor
    while i >= 0 {
        switch analysis.tokens[i] {
        case .lBrace,
             .rBrace:
            return nil

        case .equals:
            return ecPreviousSignificantWord(
                tokens: analysis.tokens,
                before: i
            )

        default:
            break
        }

        if i == 0 {
            break
        }

        i -= 1
    }

    return nil
}

func ecDocumentIDOccurrences(
    tokens: [EntryCompilerToken],
    spans: [SourceSpan]
) -> [ECDocumentIDOccurrence] {
    var out: [ECDocumentIDOccurrence] = []
    var stack: [ECEditorBlockKind] = []

    @inline(__always)
    func activeNamespace() -> ECDocumentIDNamespace? {
        switch stack.last {
        case .entry:
            return .entry

        case .transaction:
            return .transaction

        default:
            return nil
        }
    }

    for index in tokens.indices {
        let token = tokens[index]

        switch token {
        case .lBrace:
            stack.append(
                ecBlockKindIntroduced(
                    tokens: tokens,
                    before: index
                ) ?? .anonymous
            )

        case .rBrace:
            if !stack.isEmpty {
                stack.removeLast()
            }

        case .keyword("id"),
             .ident("id"):
            guard let namespace = activeNamespace() else {
                continue
            }

            guard index + 2 < tokens.count else {
                continue
            }

            guard tokens[index + 1] == .equals else {
                continue
            }

            guard case .number(let decimal) = tokens[index + 2] else {
                continue
            }

            out.append(
                ECDocumentIDOccurrence(
                    namespace: namespace,
                    id: NSDecimalNumber(decimal: decimal).intValue,
                    span: spans[index + 2]
                )
            )

        default:
            break
        }
    }

    return out
}
