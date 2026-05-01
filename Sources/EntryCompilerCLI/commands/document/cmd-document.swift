import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces
import Milieu
import Writers

enum DocumentCLIError: LocalizedError {
    case noDocumentsFound(URL)
    case documentNotFound(String)
    case pdfRenderingFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noDocumentsFound(let root):
            return "No documents found in \(root.appendingPathComponent("documents", isDirectory: true).path)"

        case .documentNotFound(let id):
            return "No document found with id '\(id)'."

        case .pdfRenderingFailed(let url):
            return "PDF rendering did not produce output at: \(url.path)"
        }
    }
}

enum DocumentEnvironment: String, CaseIterable, EnvironmentExtractable {
    case projectRoot = "EC_PROJECT_ROOT"
    case signature = "SIGNATURE"

    var key: EnvironmentExtractableKey {
        .symbol(rawValue)
    }
}

enum DocumentCommand: ArgumentCommand {
    static let name = "document"

    static let children: [ArgumentCommandType] = [
        List.self,
        Render.self,
    ]

    struct List: BoundArgumentCommand {
        static let name = "list"

        struct Options: ArgumentGroup {
            @Opt(
                "project",
                short: "p"
            )
            var projectPath: String?

            @Flag("trace")
            var trace: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let root = resolveDocumentProjectRoot(
                from: options.projectPath
            )

            let documents = try loadDocuments(
                root: root,
                trace: options.trace
            )

            guard !documents.isEmpty else {
                throw DocumentCLIError.noDocumentsFound(
                    root
                )
            }

            for document in documents {
                print("\(document.id) [\(document.kind.rawValue)]")
            }
        }
    }

    struct Render: BoundArgumentCommand {
        static let name = "render"

        struct Options: ArgumentGroup {
            @Opt(
                "project",
                short: "p"
            )
            var projectPath: String?

            @Opt("id")
            var id: String?

            @Flag("all")
            var all: Bool

            @Opt(
                "margins",
                default: 40.0
            )
            var margins: Double

            @Flag("html")
            var html: Bool

            @Flag(
                "pdf",
                default: true
            )
            var pdf: Bool

            @Flag("overwrite")
            var overwrite: Bool

            @Flag("backup")
            var backup: Bool

            @Flag(
                "whitespace-only-is-blank",
                default: true
            )
            var whitespaceOnlyIsBlank: Bool

            @Opt(
                "backup-suffix",
                default: "_previous_version.bak"
            )
            var backupSuffix: String

            @Flag("trace")
            var trace: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let root = resolveDocumentProjectRoot(
                from: options.projectPath
            )

            let project = EntryCompilerProject(
                root: root
            )

            let documents = try loadDocuments(
                root: root,
                trace: options.trace
            )

            let selected = try selectDocuments(
                from: documents,
                root: root,
                id: options.id,
                renderAll: options.all
            )

            let outDir = project.url(
                .statements
            )

            try FileManager.default.createDirectory(
                at: outDir,
                withIntermediateDirectories: true
            )

            let safeWriteOptions = makeSafeWriteOptions(
                overwrite: options.overwrite,
                backup: options.backup,
                whitespaceOnlyIsBlank: options.whitespaceOnlyIsBlank,
                backupSuffix: options.backupSuffix
            )

            let signatureImagePath = resolveDocumentSignatureImagePath()

            for original in selected {
                let document = applyingSignatureImagePath(
                    signatureImagePath,
                    to: original
                )

                let base = documentOutputBaseName(
                    document
                )

                let renderedHTML = try ECDocumentRenderer.renderHTML(
                    document
                )

                if options.html {
                    let htmlURL = outDir.appendingPathComponent(
                        "\(base).html"
                    )

                    let result = try SafeFile(htmlURL).write(
                        renderedHTML,
                        options: safeWriteOptions
                    )

                    print(result.description)
                }

                if options.pdf {
                    let pdfURL = outDir.appendingPathComponent(
                        "\(base).pdf"
                    )

                    try preflightSafeWrite(
                        [
                            pdfURL,
                        ],
                        options: safeWriteOptions
                    )

                    try renderedHTML.weasyPDF(
                        css: CSSPageSetting(
                            margins: CSSMargins(options.margins)
                        ),
                        destination: pdfURL.path
                    )

                    guard FileManager.default.fileExists(
                        atPath: pdfURL.path
                    ) else {
                        throw DocumentCLIError.pdfRenderingFailed(
                            pdfURL
                        )
                    }

                    print("Created \(pdfURL.path)")
                }
            }
        }
    }
}

private func resolveDocumentProjectRoot(
    from explicit: String?
) -> URL {
    if let explicit,
       !explicit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return EntryCompilerProject.resolveRoot(
            from: explicit
        )
    }

    if let env = try? DocumentEnvironment.projectRoot.value() {
        let trimmed = env.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if !trimmed.isEmpty {
            return EntryCompilerProject.resolveRoot(
                from: trimmed
            )
        }
    }

    return EntryCompilerProject.resolveRoot(
        from: nil
    )
}

private func resolveDocumentSignatureImagePath() -> String? {
    guard let env = try? DocumentEnvironment.signature.value() else {
        return nil
    }

    let trimmed = env.trimmingCharacters(
        in: .whitespacesAndNewlines
    )

    return trimmed.isEmpty ? nil : trimmed
}

private func applyingSignatureImagePath(
    _ path: String?,
    to document: ECDocument
) -> ECDocument {
    guard let path,
          !path.isEmpty else {
        return document
    }

    return ECDocument(
        id: document.id,
        kind: document.kind,
        title: document.title,
        subtitle: document.subtitle,
        recipient: document.recipient,
        subjectPrefix: document.subjectPrefix,
        senderName: document.senderName,
        senderRole: document.senderRole,
        place: document.place,
        date: document.date,
        periods: document.periods,
        footerLines: document.footerLines,
        administratorLines: document.administratorLines,
        footerNote: document.footerNote,
        metaRows: document.metaRows,
        blocks: document.blocks,
        assets: ECDocumentAssets(
            signatureImagePath: path
        )
    )
}

private func loadDocuments(
    root: URL,
    trace: Bool
) throws -> [ECDocument] {
    let project = EntryCompilerProject(
        root: root
    )

    let settings = try EntryCompilerSettingsLoader.load(
        from: root,
        trace: trace
    )

    return try ECDocumentLoader.load(
        from: project,
        settings: settings,
        verbose: false,
        trace: trace
    )
}

private func selectDocuments(
    from allDocuments: [ECDocument],
    root: URL,
    id: String?,
    renderAll: Bool
) throws -> [ECDocument] {
    guard !allDocuments.isEmpty else {
        throw DocumentCLIError.noDocumentsFound(
            root
        )
    }

    if renderAll {
        return allDocuments
    }

    if let id,
       !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let matches = allDocuments.filter { document in
            document.id == id
        }

        guard !matches.isEmpty else {
            throw DocumentCLIError.documentNotFound(
                id
            )
        }

        return matches
    }

    if allDocuments.count == 1 {
        return allDocuments
    }

    throw EntryCompilerCLIError.validation(
        "Multiple documents found. Pass --id <document-id> or use --all."
    )
}

private func documentOutputBaseName(
    _ document: ECDocument
) -> String {
    document.id
}
