import Foundation

public extension ECEditorService {
    static func diagnostics(
        analysis: ECDocumentAnalysis,
        workspace: ECWorkspaceIndex?,
        documentFilePath: String? = nil
    ) -> [ECDocumentDiagnostic] {
        var out = analysis.diagnostics

        guard analysis.flavor == .entries else {
            return ecDedupeDiagnostics(out)
        }

        out += entryBalanceDiagnostics(
            tokens: analysis.tokens,
            spans: analysis.spans
        )

        guard let workspace else {
            return ecDedupeDiagnostics(out)
        }

        let currentPath = documentFilePath.map {
            URL(fileURLWithPath: $0).standardizedFileURL.path
        }

        let occurrences = ecDocumentIDOccurrences(
            tokens: analysis.tokens,
            spans: analysis.spans
        )

        for occurrence in occurrences where occurrence.namespace == .entry {
            guard let existing = workspace.entryDefinitionByID[occurrence.id] else {
                continue
            }

            let existingPath = URL(fileURLWithPath: existing.file)
                .standardizedFileURL
                .path

            if let currentPath, currentPath == existingPath {
                continue
            }

            let shortFile = URL(fileURLWithPath: existing.file).lastPathComponent

            out.append(
                ECDocumentDiagnostic(
                    severity: .warning,
                    code: "duplicateEntryIDWorkspace",
                    message: "Entry id \(occurrence.id) already exists in \(shortFile):\(existing.line).",
                    span: occurrence.span
                )
            )
        }

        return ecDedupeDiagnostics(out)
    }
}

private struct ECEntryBalanceState {
    let anchorSpan: SourceSpan
    var idSpan: SourceSpan?
    var debitTotal: Decimal
    var creditTotal: Decimal
}

private func entryBalanceDiagnostics(
    tokens: [EntryCompilerToken],
    spans: [SourceSpan]
) -> [ECDocumentDiagnostic] {
    var out: [ECDocumentDiagnostic] = []
    var stack: [ECEditorBlockKind] = []
    var entryStatesByDepth: [Int: ECEntryBalanceState] = [:]

    for index in tokens.indices {
        let token = tokens[index]

        switch token {
        case .lBrace:
            let kind = ecBlockKindIntroduced(
                tokens: tokens,
                before: index
            ) ?? .anonymous

            stack.append(kind)

            if kind == .entry {
                let depth = stack.count
                let anchorIndex = ecPreviousSignificantIndex(
                    tokens: tokens,
                    before: index
                ) ?? index

                entryStatesByDepth[depth] = ECEntryBalanceState(
                    anchorSpan: spans[anchorIndex],
                    idSpan: nil,
                    debitTotal: 0,
                    creditTotal: 0
                )
            }

        case .rBrace:
            let depth = stack.count

            if let state = entryStatesByDepth.removeValue(forKey: depth),
               state.debitTotal != state.creditTotal {
                out.append(
                    ECDocumentDiagnostic(
                        severity: .warning,
                        code: "entryDebitsCreditsMismatch",
                        message: "Entry debits \(ecDecimalText(state.debitTotal)) do not equal credits \(ecDecimalText(state.creditTotal)).",
                        span: state.idSpan ?? state.anchorSpan
                    )
                )
            }

            if !stack.isEmpty {
                stack.removeLast()
            }

        case .keyword("id"),
             .ident("id"):
            guard let entryDepth = stack.lastIndex(of: .entry).map({ $0 + 1 }),
                  entryDepth == stack.count,
                  index + 2 < tokens.count,
                  tokens[index + 1] == .equals,
                  case .number = tokens[index + 2],
                  var state = entryStatesByDepth[entryDepth]
            else {
                break
            }

            state.idSpan = spans[index + 2]
            entryStatesByDepth[entryDepth] = state

        case .keyword(let name),
             .ident(let name):
            guard ecIsPostingAmountKey(name) else {
                break
            }

            guard let entryDepth = stack.lastIndex(of: .entry).map({ $0 + 1 }),
                  index + 2 < tokens.count,
                  tokens[index + 1] == .equals,
                  case .number(let amount) = tokens[index + 2],
                  var state = entryStatesByDepth[entryDepth]
            else {
                break
            }

            let scope = stack.suffix(from: entryDepth)

            guard !scope.contains(.metadata),
                  !scope.contains(.details)
            else {
                break
            }

            switch name {
            case "debit", "dr":
                state.debitTotal += amount

            case "credit", "cr":
                state.creditTotal += amount

            default:
                break
            }

            entryStatesByDepth[entryDepth] = state

        default:
            break
        }
    }

    return out
}

@inline(__always)
private func ecIsPostingAmountKey(
    _ value: String
) -> Bool {
    switch value {
    case "debit",
         "dr",
         "credit",
         "cr":
        return true

    default:
        return false
    }
}

@inline(__always)
private func ecDecimalText(
    _ value: Decimal
) -> String {
    NSDecimalNumber(decimal: value).stringValue
}

func ecDedupeDiagnostics(
    _ diagnostics: [ECDocumentDiagnostic]
) -> [ECDocumentDiagnostic] {
    var seen = Set<String>()
    var out: [ECDocumentDiagnostic] = []
    out.reserveCapacity(diagnostics.count)

    for diagnostic in diagnostics {
        let key = [
            diagnostic.severity.rawValue,
            diagnostic.code,
            diagnostic.message,
            "\(diagnostic.span.start.line)",
            "\(diagnostic.span.start.column)",
            "\(diagnostic.span.end.line)",
            "\(diagnostic.span.end.column)"
        ].joined(separator: "|")

        if seen.insert(key).inserted {
            out.append(diagnostic)
        }
    }

    return out
}
