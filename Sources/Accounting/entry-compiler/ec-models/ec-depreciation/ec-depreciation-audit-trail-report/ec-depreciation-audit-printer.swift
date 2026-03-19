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

            // === Amount totals (all periods) ===
            let exactAmt = items.lazy
                .filter { $0.coverage == .exact }
                .reduce(Decimal(0)) { $0 + $1.expected }

            let tolAmt = items.lazy
                .filter { $0.coverage == .withinTolerance }
                .reduce(Decimal(0)) { $0 + $1.expected }

            var deficits: Decimal = 0
            var surplus:  Decimal = 0
            for it in items where it.coverage == .none {
                if it.expected > it.actual {
                    deficits += (it.expected - it.actual)
                } else if it.actual > it.expected {
                    surplus  += (it.actual - it.expected)
                }
            }
            let misalignedAmt = deficits + surplus

            out.append("")
            out.append("Amounts:")
            out.append("  • total exact: \(fmt(exactAmt))")
            out.append("  • total within tolerance: \(fmt(tolAmt))")
            out.append("  • total misaligned: \(fmt(misalignedAmt))")
            out.append("     ├─ total deficits: \(fmt(deficits))")
            out.append("     └─ total surplus:  \(fmt(surplus))")

            // === Amount totals PER YEAR ===
            // place this right after the “Amounts:” block and before the per-period section
            let _cal = Calendar(identifier: .iso8601)
            var byYear: [Int: [DepreciationAuditItem]] = [:]
            for it in items {
                byYear[_cal.component(.year, from: it.periodStart), default: []].append(it)
            }

            out.append("")
            out.append("Per-year amounts:")
            for y in byYear.keys.sorted() {
                let bucket = byYear[y]!

                let yExact = bucket.lazy
                    .filter { $0.coverage == .exact }
                    .reduce(Decimal(0)) { $0 + $1.expected }

                let yTol = bucket.lazy
                    .filter { $0.coverage == .withinTolerance }
                    .reduce(Decimal(0)) { $0 + $1.expected }

                var yDef: Decimal = 0
                var ySur: Decimal = 0
                for it in bucket where it.coverage == .none {
                    if it.expected > it.actual { yDef += (it.expected - it.actual) }
                    else if it.actual > it.expected { ySur += (it.actual - it.expected) }
                }
                let yMis = yDef + ySur

                out.append("  \(y)")
                out.append("    • total exact: \(fmt(yExact))")
                out.append("    • total within tolerance: \(fmt(yTol))")
                out.append("    • total misaligned: \(fmt(yMis))")
                out.append("       ├─ total deficits: \(fmt(yDef))")
                out.append("       └─ total surplus:  \(fmt(ySur))")
            }

            // === Amount totals PER PERIOD ===
            struct _PKey: Hashable { let s: Date; let e: Date }
            var byPeriod: [_PKey: [DepreciationAuditItem]] = [:]
            for it in items {
                byPeriod[_PKey(s: it.periodStart, e: it.periodEnd), default: []].append(it)
            }

            let _df = ISO8601DateFormatter()
            if opts.useISODateOnly { _df.formatOptions = [.withFullDate] }

            out.append("")
            out.append("Per-period amounts:")
            for k in byPeriod.keys.sorted(by: { $0.s < $1.s }) {
                let bucket = byPeriod[k]!

                let pExact = bucket.lazy
                    .filter { $0.coverage == .exact }
                    .reduce(Decimal(0)) { $0 + $1.expected }

                let pTol = bucket.lazy
                    .filter { $0.coverage == .withinTolerance }
                    .reduce(Decimal(0)) { $0 + $1.expected }

                var pDef: Decimal = 0
                var pSur: Decimal = 0
                for it in bucket where it.coverage == .none {
                    if it.expected > it.actual {
                        pDef += (it.expected - it.actual)
                    } else if it.actual > it.expected {
                        pSur += (it.actual - it.expected)
                    }
                }
                let pMis = pDef + pSur

                out.append("  \(_df.string(from: k.s)) → \(_df.string(from: k.e))")
                out.append("    • total exact: \(fmt(pExact))")
                out.append("    • total within tolerance: \(fmt(pTol))")
                out.append("    • total misaligned: \(fmt(pMis))")
                out.append("       ├─ total deficits: \(fmt(pDef))")
                out.append("       └─ total surplus:  \(fmt(pSur))")
            }
            // END OF AMOUNT TOTALS
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
