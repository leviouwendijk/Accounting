import Accounting
import AccountingCompiler

/// Terminal presentation only. No output originates from AccountingCompiler.
enum EntryPlaceholderCLIReporter {
    static func emit(entries: [Entry], verbose: Bool) {
        let report = EntryPlaceholderInspector.inspect(entries: entries)
        guard report.totalOccurrences > 0 else { return }
        if !verbose {
            print("! WARNING: Placeholder entities detected")
            print("entries affected: \(report.affectedEntryCount)")
            print("total placeholders: \(report.totalOccurrences)")
            print()
            return
        }
        for entryIndex in 0..<report.entryCount {
            let matches = report.findings.filter { $0.entryIndex == entryIndex }
            guard let first = matches.first else { continue }
            for finding in matches {
                print("! WARNING: Placeholder detected")
                if let kind = finding.kind {
                    print("    kind: \"\(kind.rawValue)\"")
                }
                print("    alias: \"\(finding.entityAlias)\"")
                print("    detection: \(finding.detection.rawValue)")
                if let location = finding.location {
                    print("    at: \(location.description)")
                }
            }
            print("placeholders in entry (id: \(first.entryID.map(String.init) ?? "unknown")): \(matches.count)")
            print()
        }
    }
}
