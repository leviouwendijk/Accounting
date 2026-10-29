import Accounting
import AccountingCompiler
import Foundation
import IO
import Path
import TestFlows
import Workspace

extension AccountingTestFlowsSuite {
    static var accountingPathWorkspaceFlow: TestFlow {
        TestFlow("accounting-path-workspace", tags: ["accounting", "path", "workspace"]) {
            Step("typed period layouts are reusable, validated and reversible") {
                let period = try EntrySourcePeriod(year: 2026, quarter: 2, month: 4)
                let live = try EntrySourcePath.render(period: period, filenameStem: "main")
                let trash = try EntrySourcePath.render(period: period, filenameStem: "main", archived: true)
                try Expect.equal(live.segments.map(\.value), ["entries", "2026", "2", "4", "main.ec"], "live canonical")
                try Expect.equal(trash.segments.map(\.value), ["archive", "trash", "2026", "2", "4", "main.ec"], "archive canonical")
                try Expect.equal(try EntrySourcePath.period(from: live), period, "live period roundtrip")
                try Expect.equal(try EntrySourcePath.period(from: trash), period, "trash period roundtrip")
                try Expect.equal(try inferEntrySourcePeriod(from: "/different/root/entries/2026/2/4/main.ec"), period, "variable root")
                try Expect.throwsError("quarter/month mismatch rejected") {
                    _ = try inferEntrySourcePeriod(from: "/entries/2026/1/4/main.ec")
                }
                try Expect.throwsError("malformed numeric segment rejected") {
                    _ = try inferEntrySourcePeriod(from: "/entries/invalid/2/4/main.ec")
                }
                try Expect.throwsError("path traversal through stem rejected") {
                    _ = try EntrySourcePath.render(period: period, filenameStem: "../escape")
                }
            }

            Step("workspace compiler reads are explicitly granted; denied reads do not fall back") {
                let fm = FileManager.default
                let root = fm.temporaryDirectory.appendingPathComponent("accounting-ws-\(UUID().uuidString)", isDirectory: true)
                let entries = root.appendingPathComponent("entries", isDirectory: true)
                try fm.createDirectory(at: entries, withIntermediateDirectories: true)
                defer { try? fm.removeItem(at: root) }
                let file = entries.appendingPathComponent("main.ec")
                try "entry { id = 1 date = 2026-04-12 }".write(to: file, atomically: true, encoding: .utf8)
                let rootID = PathAccessRootIdentifier(rawValue: "project")
                let installed = PathAccessRoot(
                    id: rootID,
                    label: "Accounting project",
                    scope: try PathAccessScope(root: root, policy: .defaults.workspace),
                    isDefault: true
                )
                let scanOnly = try WorkspaceGrant(
                    id: WorkspaceGrantIdentifier("accounting-scan"),
                    rootIdentifier: rootID,
                    capabilities: [.scan]
                )
                let readOnly = try WorkspaceGrant(
                    id: WorkspaceGrantIdentifier("accounting-read"),
                    rootIdentifier: rootID,
                    capabilities: [.read]
                )
                let workspaceWithoutRead = try Workspace(root: installed, grants: [scanOnly])
                let deniedProject = EntryCompilerProject(workspace: try workspaceWithoutRead.context(
                    execution: .init(io: .blocking, mutations: .immediate)
                ))
                try Expect.throwsError("scan alone cannot read individual files") {
                    _ = try deniedProject.ecFileURLs(at: deniedProject.url(.entries))
                }
                try Expect.throwsError("direct reader cannot bypass denied read") {
                    _ = try deniedProject.readECSource(at: file)
                }

                let workspace = try Workspace(root: installed, grants: [scanOnly, readOnly])
                let project = EntryCompilerProject(workspace: try workspace.context(
                    execution: .init(io: .blocking, mutations: .immediate)
                ))
                let files = try project.ecFileURLs(at: project.url(.entries))
                try Expect.equal(files.count, 1, "scan inventory count")
                try Expect.equal(try project.readECSource(at: files[0]), "entry { id = 1 date = 2026-04-12 }", "authorized source")
                let settings = try ECModelFixtures.parseSettings()
                let loaded = try await EntryCompilerEntriesLoader.load(
                    from: project, settings: settings, trace: false
                )
                try Expect.equal(loaded.compactMap(\.id), [1], "authorized sync loader")
                let concurrent = try await EntryCompilerEntriesLoader.load(
                    from: project, settings: settings, trace: false
                )
                try Expect.equal(concurrent.compactMap(\.id), [1], "authorized async loader")
                try Expect.throwsError("out-of-workspace target rejected") {
                    _ = try project.readECSource(at: root.deletingLastPathComponent().appendingPathComponent("outside.ec"))
                }
                let outside = root.deletingLastPathComponent()
                    .appendingPathComponent("accounting-outside-\(UUID().uuidString).ec")
                defer { try? fm.removeItem(at: outside) }
                try "sensitive".write(to: outside, atomically: true, encoding: .utf8)
                let link = entries.appendingPathComponent("outside-link.ec")
                try fm.createSymbolicLink(at: link, withDestinationURL: outside)
                try Expect.throwsError("symlink outside workspace denied") {
                    _ = try project.readECSource(at: link)
                }
            }
        }
    }
}
