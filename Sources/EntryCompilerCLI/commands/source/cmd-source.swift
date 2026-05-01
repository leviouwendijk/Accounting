import Accounting
import AccountingCompiler
import Arguments
import Foundation
import Interfaces
import Writers

enum SourceCLIError: LocalizedError {
    case noMatchingEntryIDs([Int])
    case noMatchingGroups([String])
    case pdfRenderingFailed(URL)

    var errorDescription: String? {
        switch self {
        case .noMatchingEntryIDs(let ids):
            return "No entry blocks matched requested ids: \(ids.map(String.init).joined(separator: ", "))"

        case .noMatchingGroups(let groups):
            return "No entry blocks matched requested groups: \(groups.joined(separator: ", "))"

        case .pdfRenderingFailed(let url):
            return "PDF rendering did not produce output at: \(url.path)"
        }
    }
}

enum SourceCommand: ArgumentCommand {
    static let name = "source"

    static let children: [ArgumentCommandType] = [
        Render.self,
    ]

    struct Render: BoundArgumentCommand {
        static let name = "render"

        struct Options: ArgumentGroup {
            @Opt(
                "project",
                short: "p"
            )
            var projectPath: String?

            @Arg(
                "scope",
                default: "entries"
            )
            var scope: String

            @Opts(
                "id",
                take: .many
            )
            var id: [String]

            @Opts(
                "group",
                take: .many
            )
            var group: [String]

            @Opts(
                "path",
                take: .many
            )
            var path: [String]

            @Opt("title")
            var title: String?

            @Opt("subtitle")
            var subtitle: String?

            @Flag(
                "line-numbers",
                default: true
            )
            var lineNumbers: Bool

            @Flag(
                "compact",
                default: true
            )
            var compact: Bool

            @Flag("html")
            var html: Bool

            @Flag("pdf")
            var pdf: Bool

            @Opt(
                "margins",
                default: 28.0
            )
            var margins: Double

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

            @Flag("no-terminal")
            var noTerminal: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let root = EntryCompilerProject.resolveRoot(
                from: options.projectPath
            )

            let project = EntryCompilerProject(
                root: root
            )

            let scope = try EntryCompilerProject.Scope.parse(
                from: options.scope
            )

            let requestedIDs = try ECSourceSelection.parseIntegerSelection(
                options.id,
                argumentName: "--id"
            )

            let requestedGroups = ECSourceSelection.parseNormalizedGroupSelection(
                options.group
            )

            var files = try ECSourceSelection.collectFiles(
                root: root,
                scopeURLs: project.urls(scope),
                explicitPaths: options.path
            )

            if !requestedIDs.isEmpty {
                files = ECSourceSelection.filterFiles(
                    files,
                    matchingEntryIDs: Set(requestedIDs)
                )

                guard !files.isEmpty else {
                    throw SourceCLIError.noMatchingEntryIDs(
                        requestedIDs
                    )
                }
            }

            if !requestedGroups.isEmpty {
                files = ECSourceSelection.filterFiles(
                    files,
                    matchingGroups: Set(requestedGroups)
                )

                guard !files.isEmpty else {
                    throw SourceCLIError.noMatchingGroups(
                        requestedGroups
                    )
                }
            }

            let outDir = project.url(
                .statements
            )

            try FileManager.default.createDirectory(
                at: outDir,
                withIntermediateDirectories: true
            )

            let presentationOptions = ECSourcePresentationOptions(
                title: options.title ?? "EC Source",
                subtitle: options.subtitle ?? ECSourceSelection.selectionLabel(
                    scopeLabel: scope.rawValue,
                    explicitPaths: options.path,
                    ids: requestedIDs,
                    groups: requestedGroups
                ),
                showLineNumbers: options.lineNumbers,
                compact: options.compact,
                includeFileBlockCounts: true,
                syntaxHighlighting: true
            )

            let terminal = ECSourceTerminalRenderer.render(
                files: files,
                options: presentationOptions
            )

            let renderedHTML = ECSourceHTMLRenderer.render(
                files: files,
                options: presentationOptions
            )

            let baseName = ECSourceSelection.outputBaseName(
                scopeLabel: scope.rawValue,
                explicitPaths: options.path,
                ids: requestedIDs,
                groups: requestedGroups
            )

            let safeWriteOptions = makeSafeWriteOptions(
                overwrite: options.overwrite,
                backup: options.backup,
                whitespaceOnlyIsBlank: options.whitespaceOnlyIsBlank,
                backupSuffix: options.backupSuffix
            )

            if !options.noTerminal {
                print(terminal)
            }

            if options.html {
                let htmlURL = outDir.appendingPathComponent(
                    "\(baseName).html"
                )

                let result = try SafeFile(htmlURL).write(
                    renderedHTML,
                    options: safeWriteOptions
                )

                print(result.description)
            }

            if options.pdf {
                let pdfURL = outDir.appendingPathComponent(
                    "\(baseName).pdf"
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
                    throw SourceCLIError.pdfRenderingFailed(
                        pdfURL
                    )
                }

                print("Created \(pdfURL.path)")
            }
        }
    }
}
