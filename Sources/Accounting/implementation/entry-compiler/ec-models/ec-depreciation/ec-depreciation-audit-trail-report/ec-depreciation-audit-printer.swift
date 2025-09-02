import Foundation

public extension DepreciationAuditReport {
    /// Produce a CLI-friendly string rendering of the audit report.
    func renderText(_ opts: DepreciationAuditTextOptions = .init()) -> String {
        @inline(__always)
        func fmt(_ x: Decimal) -> String {
            guard let digits = opts.fractionDigits else { return x.description }
            var v = x, out = Decimal()
            NSDecimalRound(&out, &v, digits, .plain)           // presentation-only
            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US_POSIX")
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = digits
            nf.maximumFractionDigits = digits
            nf.minimumIntegerDigits = 1
            return nf.string(from: out as NSDecimalNumber) ?? out.description
        }

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
                if opts.showAllGoodLine { out.append("• all as expected ") }
                return out.joined(separator: "\n")
            }
            out.append("")
            out.append("Failures:")
            let df = ISO8601DateFormatter()
            if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

            for f in failures {
                out.append("mismatch".ansi(.yellow))
                let period = "\(df.string(from: f.periodStart)) → \(df.string(from: f.periodEnd))"
                out.append("    • \(f.entity.identifier(displaying: .fullchain))")
                out.append("    to [\(f.account.code)]")
                out.append("    period \(period)")
                out.append("        expected: \(fmt(f.expected))")
                out.append("        got: \(fmt(f.actual))")
                out.append("        Δ = \(fmt(f.delta))")
                if let note = f.note, !note.isEmpty {
                    out.append("    note: \(note)")
                }
                for d in f.details.prefix(opts.maxFailureDetailLines) {
                    out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))")
                }
                if f.details.count > opts.maxFailureDetailLines {
                    out.append("    ↳ (+\(f.details.count - opts.maxFailureDetailLines) more)")
                }
                out.append("")
            }
            return out.joined(separator: "\n")
        } else {
            let df = ISO8601DateFormatter()
            if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

            for it in items {
                // status line resembling failures style
                switch it.coverage {
                case .exact:
                    out.append("match".ansi(.green))
                case .withinTolerance:
                    out.append("match (±tol)".ansi(.green))
                case .aggregateCovered:
                    out.append("aggregate covered".ansi(.green))
                case .none:
                    out.append("mismatch".ansi(.yellow))
                }

                let period = "\(df.string(from: it.periodStart)) → \(df.string(from: it.periodEnd))"
                out.append("    • \(it.entity.identifier(displaying: .fullchain)) [\(it.account.code)]  \(period)")
                out.append("        expected: \(fmt(it.expected))")
                out.append("        got: \(fmt(it.actual))")
                out.append("        Δ = \(fmt(it.delta))")

                if let note = it.note, !note.isEmpty {
                    out.append("    note: \(note)")
                }
                for d in it.details.prefix(opts.maxFailureDetailLines) {
                    out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))")
                }
                if it.details.count > opts.maxFailureDetailLines {
                    out.append("    ↳ (+\(it.details.count - opts.maxFailureDetailLines) more)")
                }
                out.append("")
            }
            return out.joined(separator: "\n")
        }
    }
}
