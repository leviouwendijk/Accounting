import Foundation

public struct DepreciationAuditTextOptions: Sendable, Codable {
    public var title: String = "Depreciation audit"
    public var underline: String = "──────────────────"
    public var showHeader: Bool = true
    public var onlyFailures: Bool = true
    public var maxFailureDetailLines: Int = 6
    public var showAllGoodLine: Bool = true     // prints "• all good" when there are no failures
    public var useISODateOnly: Bool = true      // ISO date without time
    public var includeSummaryBlock: Bool = true // periods checked / exact / within tol / aggregate covered / failures

    public init() {}
}

public extension DepreciationAuditReport {
    /// Produce a CLI-friendly string rendering of the audit report.
    func renderText(_ opts: DepreciationAuditTextOptions = .init()) -> String {
        var out: [String] = []
        let failures = self.failures

        if opts.showHeader {
            out.append("")
            out.append(opts.title)
            out.append(opts.underline)
        }

        if opts.includeSummaryBlock {
            let total   = items.count
            let exact   = items.filter { $0.coverage == .exact }.count
            let tol     = items.filter { $0.coverage == .withinTolerance }.count
            let agg     = items.filter { $0.coverage == .aggregateCovered }.count
            let failCnt = failures.count

            out.append("• periods checked: \(total)")
            out.append("• exact: \(exact)   within tol: \(tol)   aggregate covered: \(agg)   failures: \(failCnt)")
        }

        if opts.onlyFailures {
            if failures.isEmpty {
                if opts.showAllGoodLine {
                    out.append("• all as expected ")
                }
                return out.joined(separator: "\n")
            }
            out.append("")
            out.append("Failures:")
            let df = ISO8601DateFormatter()
            if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

            for f in failures {
                let period = "\(df.string(from: f.periodStart)) → \(df.string(from: f.periodEnd))"
                out.append("  • \(f.entity.identifier(displaying: .fullchain)) [\(f.account.code)]  \(period)")
                out.append("    expected \(f.expected)  got \(f.actual)  Δ=\(f.delta)")
                if let note = f.note, !note.isEmpty {
                    out.append("    note: \(note)")
                }
                for d in f.details.prefix(opts.maxFailureDetailLines) {
                    out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(d.amount)")
                }
                if f.details.count > opts.maxFailureDetailLines {
                    out.append("    ↳ (+\(f.details.count - opts.maxFailureDetailLines) more)")
                }
            }
            return out.joined(separator: "\n")
        } else {
            // Print all items (rarely needed, but offered for completeness)
            let df = ISO8601DateFormatter()
            if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

            for it in items {
                let period = "\(df.string(from: it.periodStart)) → \(df.string(from: it.periodEnd))"
                out.append("• \(it.entity.identifier(displaying: .fullchain)) [\(it.account.code)]  \(period)  \(it.coverage.rawValue)")
                out.append("  expected \(it.expected)  got \(it.actual)  Δ=\(it.delta)")
            }
            return out.joined(separator: "\n")
        }
    }
}
