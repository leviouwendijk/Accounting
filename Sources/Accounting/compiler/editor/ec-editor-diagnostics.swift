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
