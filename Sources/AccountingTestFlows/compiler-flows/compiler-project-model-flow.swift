import Accounting
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var compilerProjectModelFlow: TestFlow {
        TestFlow(
            "compiler-project-model",
            tags: [
                "compiler",
                "project",
                "filesystem",
            ]
        ) {
            Step("project URLs resolve canonical base directories") {
                let root = URL(
                    fileURLWithPath: "/tmp/accounting-testflows-project",
                    isDirectory: true
                )

                let project = EntryCompilerProject(
                    root: root
                )

                try Expect.equal(
                    project.url(.config).lastPathComponent,
                    "config",
                    "compiler-project-model.config"
                )

                try Expect.equal(
                    project.url(.entries).lastPathComponent,
                    "entries",
                    "compiler-project-model.entries"
                )

                try Expect.equal(
                    project.url(.transactions).lastPathComponent,
                    "transactions",
                    "compiler-project-model.transactions"
                )

                try Expect.equal(
                    project.url(.documents).lastPathComponent,
                    "documents",
                    "compiler-project-model.documents"
                )

                try Expect.equal(
                    project.url(.statements).lastPathComponent,
                    "statements",
                    "compiler-project-model.statements"
                )
            }

            Step("project subpaths apply ec extension for file components") {
                let root = URL(
                    fileURLWithPath: "/tmp/accounting-testflows-project",
                    isDirectory: true
                )

                let project = EntryCompilerProject(
                    root: root
                )

                try Expect.equal(
                    project.url(
                        .config,
                        .settings
                    ).lastPathComponent,
                    "settings.ec",
                    "compiler-project-model.settings"
                )

                try Expect.equal(
                    project.url(
                        .config,
                        .aggregation
                    ).lastPathComponent,
                    "aggregation.ec",
                    "compiler-project-model.aggregation"
                )

                try Expect.equal(
                    project.url(
                        .config,
                        .accounts
                    ).lastPathComponent,
                    "accounts",
                    "compiler-project-model.accounts"
                )

                try Expect.equal(
                    project.url(
                        .config,
                        .entities
                    ).lastPathComponent,
                    "entities",
                    "compiler-project-model.entities"
                )
            }

            Step("findRoot climbs to entries/config root shape") {
                let fileManager = FileManager.default
                let root = fileManager.temporaryDirectory
                    .appendingPathComponent(
                        "accounting-testflows-\(UUID().uuidString)",
                        isDirectory: true
                    )

                let nested = root
                    .appendingPathComponent(
                        "a/b/c",
                        isDirectory: true
                    )

                defer {
                    try? fileManager.removeItem(
                        at: root
                    )
                }

                try fileManager.createDirectory(
                    at: root.appendingPathComponent(
                        "entries",
                        isDirectory: true
                    ),
                    withIntermediateDirectories: true
                )

                try fileManager.createDirectory(
                    at: nested,
                    withIntermediateDirectories: true
                )

                let found = EntryCompilerProject.findRoot(
                    startingAt: nested
                )

                try Expect.equal(
                    found?.path,
                    root.standardizedFileURL.path,
                    "compiler-project-model.find-root"
                )
            }
        }
    }
}
