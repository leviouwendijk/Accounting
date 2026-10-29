import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var entryPlaceholderInspectionFlow: TestFlow {
        TestFlow("entry-placeholder-inspection", tags: ["accounting", "inspection"]) {
            Step("detect explicit and alias-only placeholders without resolution") {
                let manager = FileManager.default
                let root = manager.temporaryDirectory.appendingPathComponent(
                    "accounting-placeholders-\(UUID().uuidString)", isDirectory: true
                )
                let entriesURL = root.appendingPathComponent("entries", isDirectory: true)
                try manager.createDirectory(at: entriesURL, withIntermediateDirectories: true)
                defer { try? manager.removeItem(at: root) }
                try """
                entry {
                    id = 41
                    date = 2026-04-12
                    for placeholder(service) in (WOmzNodOdh) { credit = 10.00 }
                }
                entry { id = 46 date = 2026-04-13 }
                """.write(
                    to: entriesURL.appendingPathComponent("main.ec"),
                    atomically: true, encoding: .utf8
                )
                let project = EntryCompilerProject(root: root)
                let settings = try ECModelFixtures.parseSettings()
                let parsed = try await EntryCompilerEntriesLoader.load(
                    from: project, settings: settings, trace: false
                )
                let baseline = EntryPlaceholderInspector.inspect(entries: parsed)
                try Expect.equal(baseline.totalOccurrences, 1, "One explicit occurrence")
                try Expect.equal(baseline.affectedEntryCount, 1, "One affected entry")
                try Expect.equal(baseline.findings[0].detection, .explicit, "Explicit classification")
                try Expect.equal(baseline.findings[0].kind, .service, "Kind retained")
                try Expect.equal(baseline.findings[0].location != nil, true, "Line provenance")

                var aliasOnly = parsed[0]
                aliasOnly.lines = parsed[0].lines.map { line in
                    Line(
                        entity: EntityRef(
                            class: line.entity.class,
                            family: line.entity.family,
                            alias: line.entity.alias
                        ),
                        account: line.account,
                        direction: line.direction,
                        amount: line.amount,
                        adjustment: line.adjustment,
                        location: line.location
                    )
                }
                let mixed = EntryPlaceholderInspector.inspect(entries: [parsed[0], aliasOnly, parsed[1]])
                try Expect.equal(mixed.totalOccurrences, 2, "Explicit and fallback retained")
                try Expect.equal(mixed.affectedEntryCount, 2, "Count actual entry instances")
                try Expect.equal(mixed.findings[1].detection, .alias_suffix, "Suffix classification")
                try Expect.equal(mixed.findings[1].kind, nil, "No fabricated placeholder kind")
                try Expect.equal(EntryPlaceholderInspector.inspect(entries: []).totalOccurrences, 0, "Empty report")
                let direct = try await EntryPlaceholderInspector.inspect(project: project, settings: settings)
                let concurrent = try await EntryPlaceholderInspector.inspect(project: project, settings: settings)
                try Expect.equal(direct, concurrent, "Project sync/async parity")
            }
        }
    }
}
