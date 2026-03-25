import Foundation

public extension DepreciationAuditReport {
    /// Produce a CLI-friendly string rendering of the audit report.
    func renderText(_ opts: DepreciationAuditTextOptions = .init()) -> String {
        @inline(__always)
        func fmt(_ x: Decimal) -> String {
            guard let digits = opts.fractionDigits else {
                return x.description
            }

            var value = x
            var rounded = Decimal()
            NSDecimalRound(&rounded, &value, digits, .plain)

            let nf = NumberFormatter()
            nf.locale = Locale(identifier: "en_US_POSIX")
            nf.numberStyle = .decimal
            nf.minimumFractionDigits = digits
            nf.maximumFractionDigits = digits
            nf.minimumIntegerDigits = 1

            return nf.string(from: rounded as NSDecimalNumber) ?? rounded.description
        }

        struct Totals {
            var exact: Decimal = 0
            var withinTolerance: Decimal = 0
            var deficits: Decimal = 0
            var surplus: Decimal = 0

            var misaligned: Decimal {
                deficits + surplus
            }
        }

        @inline(__always)
        func totals(for bucket: [DepreciationAuditItem]) -> Totals {
            var out = Totals()

            for item in bucket {
                switch item.coverage {
                case .exact:
                    out.exact += item.expected

                case .withinTolerance:
                    out.withinTolerance += item.expected

                case .none:
                    if item.expected > item.actual {
                        out.deficits += (item.expected - item.actual)
                    } else if item.actual > item.expected {
                        out.surplus += (item.actual - item.expected)
                    }

                case .aggregateCovered:
                    break
                }
            }

            return out
        }

        @inline(__always)
        func appendTotalsBlock(
            _ lines: inout [String],
            indent: String,
            totals: Totals
        ) {
            lines.append("\(indent)• total exact: \(fmt(totals.exact))")
            lines.append("\(indent)• total within tolerance: \(fmt(totals.withinTolerance))")
            lines.append("\(indent)• total misaligned: \(fmt(totals.misaligned))")
            lines.append("\(indent)   ├─ total deficits: \(fmt(totals.deficits))")
            lines.append("\(indent)   └─ total surplus:  \(fmt(totals.surplus))")
        }

        @inline(__always)
        func monthKey(for date: Date, calendar: Calendar) -> String {
            let comps = calendar.dateComponents([.year, .month], from: date)
            let year = comps.year ?? 0
            let month = comps.month ?? 0
            return String(format: "%04d-%02d", year, month)
        }

        var out: [String] = []
        let items = self.items
        let failures = self.failures

        if opts.showHeader {
            out.append("")
            out.append(opts.title)
            out.append(opts.underline)
        }

        if opts.includeSummaryBlock {
            let total = items.count
            let exactCount = items.filter { $0.coverage == .exact }.count
            let tolCount = items.filter { $0.coverage == .withinTolerance }.count
            let aggCount = items.filter { $0.coverage == .aggregateCovered }.count
            let failCount = failures.count

            out.append("• periods checked: \(total)")
            out.append("• exact: \(exactCount)   within tol: \(tolCount)   aggregate covered: \(aggCount)   failures: \(failCount)")

            out.append("")
            out.append("Amounts:")
            appendTotalsBlock(&out, indent: "  ", totals: totals(for: items))

            let cal = Calendar(identifier: .iso8601)

            if opts.showPerYearAmounts {
                var byYear: [Int: [DepreciationAuditItem]] = [:]
                for item in items {
                    let year = cal.component(.year, from: item.periodStart)
                    byYear[year, default: []].append(item)
                }

                out.append("")
                out.append("Per-year amounts:")

                for year in byYear.keys.sorted() {
                    let bucket = byYear[year] ?? []
                    out.append("  \(year)")
                    appendTotalsBlock(&out, indent: "    ", totals: totals(for: bucket))
                }
            }

            if opts.showPerMonthAmounts {
                var byMonth: [String: [DepreciationAuditItem]] = [:]
                for item in items {
                    let postingMonth = DepreciationPostingWindow.postingMonthStart(
                        for: item,
                        calendar: cal
                    )
                    let key = monthKey(for: postingMonth, calendar: cal)
                    byMonth[key, default: []].append(item)
                }

                out.append("")
                out.append("Per-month amounts:")

                for month in byMonth.keys.sorted() {
                    let bucket = byMonth[month] ?? []
                    out.append("  \(month)")
                    appendTotalsBlock(&out, indent: "    ", totals: totals(for: bucket))
                }
            }

            if opts.showPerPeriodAmounts {
                struct PeriodKey: Hashable {
                    let start: Date
                    let end: Date
                }

                var byPeriod: [PeriodKey: [DepreciationAuditItem]] = [:]
                for item in items {
                    let key = PeriodKey(start: item.periodStart, end: item.periodEnd)
                    byPeriod[key, default: []].append(item)
                }

                let df = ISO8601DateFormatter()
                if opts.useISODateOnly {
                    df.formatOptions = [.withFullDate]
                }

                out.append("")
                out.append("Per-period amounts:")

                for key in byPeriod.keys.sorted(by: { lhs, rhs in
                    if lhs.start == rhs.start {
                        return lhs.end < rhs.end
                    }
                    return lhs.start < rhs.start
                }) {
                    let bucket = byPeriod[key] ?? []
                    let start = df.string(from: key.start)
                    let end = df.string(from: key.end)

                    out.append("  \(start) → \(end)")
                    appendTotalsBlock(&out, indent: "    ", totals: totals(for: bucket))
                }
            }
        }

        let failuresToRender: [DepreciationAuditItem] = {
            if opts.showFailuresEvenIfCovered {
                return items
            } else {
                return failures
            }
        }()

        if !failuresToRender.isEmpty {
            let df = ISO8601DateFormatter()
            if opts.useISODateOnly {
                df.formatOptions = [.withFullDate]
            }

            out.append("")
            out.append("Audit items:")

            for item in failuresToRender {
                let start = df.string(from: item.periodStart)
                let end = df.string(from: item.periodEnd)

                out.append("  • \(item.entity.identifier(displaying: .fullchain))")
                out.append("    account: [\(item.account.code)]")
                out.append("    range: \(start) → \(end)")
                out.append("    expected: \(fmt(item.expected))")
                out.append("    actual: \(fmt(item.actual))")
                out.append("    Δ = \(fmt(item.delta))")
                out.append("    coverage: \(String(describing: item.coverage))")

                out.append("    actual split:")
                out.append("      • auto-generated: \(fmt(item.actualAutoGenerated))")
                out.append("      • manual:         \(fmt(item.actualManual))")

                if item.surplusAutoGenerated > 0 || item.surplusManual > 0 {
                    out.append("    surplus split:")
                    out.append("      • auto-generated: \(fmt(item.surplusAutoGenerated))")
                    out.append("      • manual:         \(fmt(item.surplusManual))")
                }

                if let note = item.note, !note.isEmpty {
                    out.append("    note: \(note)")
                }

                for d in item.details.prefix(8) {
                    let suffix = d.note.map { "  \($0)" } ?? ""
                    out.append(
                        "    ↳ [\(d.origin.displayLabel)] entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))\(suffix)"
                    )
                }

                if item.details.count > 8 {
                    out.append("    ↳ (+\(item.details.count - 8) more)")
                }
            }

            // for item in failuresToRender {
            //     let start = df.string(from: item.periodStart)
            //     let end = df.string(from: item.periodEnd)

            //     out.append("  • \(item.entity.identifier(displaying: .fullchain))")
            //     out.append("    account: [\(item.account.code)]")
            //     out.append("    range: \(start) → \(end)")
            //     out.append("    expected: \(fmt(item.expected))")
            //     out.append("    actual: \(fmt(item.actual))")
            //     out.append("    Δ = \(fmt(item.delta))")
            //     out.append("    coverage: \(String(describing: item.coverage))")

            //     if let note = item.note, !note.isEmpty {
            //         out.append("    note: \(note)")
            //     }

            //     for d in item.details.prefix(8) {
            //         out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))")
            //     }

            //     if item.details.count > 8 {
            //         out.append("    ↳ (+\(item.details.count - 8) more)")
            //     }
            // }
        } else {
            out.append("• all as expected")
        }

        return out.joined(separator: "\n")
    }
}

// public extension DepreciationAuditReport {
//     /// Produce a CLI-friendly string rendering of the audit report.
//     func renderText(_ opts: DepreciationAuditTextOptions = .init()) -> String {
//         @inline(__always)
//         func fmt(_ x: Decimal) -> String {
//             guard let digits = opts.fractionDigits else { return x.description }
//             var v = x, out = Decimal()
//             NSDecimalRound(&out, &v, digits, .plain)           // presentation-only
//             let nf = NumberFormatter()
//             nf.locale = Locale(identifier: "en_US_POSIX")
//             nf.numberStyle = .decimal
//             nf.minimumFractionDigits = digits
//             nf.maximumFractionDigits = digits
//             nf.minimumIntegerDigits = 1
//             return nf.string(from: out as NSDecimalNumber) ?? out.description
//         }

//         var out: [String] = []
//         let failures = self.failures

//         if opts.showHeader {
//             out.append("")
//             out.append(opts.title)
//             out.append(opts.underline)
//         }

//         if opts.includeSummaryBlock {
//             let total   = items.count
//             let exact   = items.filter { $0.coverage == .exact }.count
//             let tol     = items.filter { $0.coverage == .withinTolerance }.count
//             let agg     = items.filter { $0.coverage == .aggregateCovered }.count
//             let failCnt = failures.count

//             out.append("• periods checked: \(total)")
//             out.append("• exact: \(exact)   within tol: \(tol)   aggregate covered: \(agg)   failures: \(failCnt)")

//             // === Amount totals (all periods) ===
//             let exactAmt = items.lazy
//                 .filter { $0.coverage == .exact }
//                 .reduce(Decimal(0)) { $0 + $1.expected }

//             let tolAmt = items.lazy
//                 .filter { $0.coverage == .withinTolerance }
//                 .reduce(Decimal(0)) { $0 + $1.expected }

//             var deficits: Decimal = 0
//             var surplus:  Decimal = 0
//             for it in items where it.coverage == .none {
//                 if it.expected > it.actual {
//                     deficits += (it.expected - it.actual)
//                 } else if it.actual > it.expected {
//                     surplus  += (it.actual - it.expected)
//                 }
//             }
//             let misalignedAmt = deficits + surplus

//             out.append("")
//             out.append("Amounts:")
//             out.append("  • total exact: \(fmt(exactAmt))")
//             out.append("  • total within tolerance: \(fmt(tolAmt))")
//             out.append("  • total misaligned: \(fmt(misalignedAmt))")
//             out.append("     ├─ total deficits: \(fmt(deficits))")
//             out.append("     └─ total surplus:  \(fmt(surplus))")

//             // === Amount totals PER YEAR ===
//             // place this right after the “Amounts:” block and before the per-period section
//             let _cal = Calendar(identifier: .iso8601)
//             var byYear: [Int: [DepreciationAuditItem]] = [:]
//             for it in items {
//                 byYear[_cal.component(.year, from: it.periodStart), default: []].append(it)
//             }

//             out.append("")
//             out.append("Per-year amounts:")
//             for y in byYear.keys.sorted() {
//                 let bucket = byYear[y]!

//                 let yExact = bucket.lazy
//                     .filter { $0.coverage == .exact }
//                     .reduce(Decimal(0)) { $0 + $1.expected }

//                 let yTol = bucket.lazy
//                     .filter { $0.coverage == .withinTolerance }
//                     .reduce(Decimal(0)) { $0 + $1.expected }

//                 var yDef: Decimal = 0
//                 var ySur: Decimal = 0
//                 for it in bucket where it.coverage == .none {
//                     if it.expected > it.actual { yDef += (it.expected - it.actual) }
//                     else if it.actual > it.expected { ySur += (it.actual - it.expected) }
//                 }
//                 let yMis = yDef + ySur

//                 out.append("  \(y)")
//                 out.append("    • total exact: \(fmt(yExact))")
//                 out.append("    • total within tolerance: \(fmt(yTol))")
//                 out.append("    • total misaligned: \(fmt(yMis))")
//                 out.append("       ├─ total deficits: \(fmt(yDef))")
//                 out.append("       └─ total surplus:  \(fmt(ySur))")
//             }

//             // === Amount totals PER PERIOD ===
//             struct _PKey: Hashable { let s: Date; let e: Date }
//             var byPeriod: [_PKey: [DepreciationAuditItem]] = [:]
//             for it in items {
//                 byPeriod[_PKey(s: it.periodStart, e: it.periodEnd), default: []].append(it)
//             }

//             let _df = ISO8601DateFormatter()
//             if opts.useISODateOnly { _df.formatOptions = [.withFullDate] }

//             out.append("")
//             out.append("Per-period amounts:")
//             for k in byPeriod.keys.sorted(by: { $0.s < $1.s }) {
//                 let bucket = byPeriod[k]!

//                 let pExact = bucket.lazy
//                     .filter { $0.coverage == .exact }
//                     .reduce(Decimal(0)) { $0 + $1.expected }

//                 let pTol = bucket.lazy
//                     .filter { $0.coverage == .withinTolerance }
//                     .reduce(Decimal(0)) { $0 + $1.expected }

//                 var pDef: Decimal = 0
//                 var pSur: Decimal = 0
//                 for it in bucket where it.coverage == .none {
//                     if it.expected > it.actual {
//                         pDef += (it.expected - it.actual)
//                     } else if it.actual > it.expected {
//                         pSur += (it.actual - it.expected)
//                     }
//                 }
//                 let pMis = pDef + pSur

//                 out.append("  \(_df.string(from: k.s)) → \(_df.string(from: k.e))")
//                 out.append("    • total exact: \(fmt(pExact))")
//                 out.append("    • total within tolerance: \(fmt(pTol))")
//                 out.append("    • total misaligned: \(fmt(pMis))")
//                 out.append("       ├─ total deficits: \(fmt(pDef))")
//                 out.append("       └─ total surplus:  \(fmt(pSur))")
//             }
//             // END OF AMOUNT TOTALS
//         }

//         if opts.onlyFailures {
//             if failures.isEmpty {
//                 if opts.showAllGoodLine { out.append("• all as expected ") }
//                 return out.joined(separator: "\n")
//             }
//             out.append("")
//             out.append("Failures:")
//             let df = ISO8601DateFormatter()
//             if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

//             for f in failures {
//                 out.append("mismatch".ansi(.yellow))
//                 let period = "\(df.string(from: f.periodStart)) → \(df.string(from: f.periodEnd))"
//                 out.append("    • \(f.entity.identifier(displaying: .fullchain))")
//                 out.append("    to [\(f.account.code)]")
//                 out.append("    period \(period)")
//                 out.append("        expected: \(fmt(f.expected))")
//                 out.append("        got: \(fmt(f.actual))")
//                 out.append("        Δ = \(fmt(f.delta))")
//                 if let note = f.note, !note.isEmpty {
//                     out.append("    note: \(note)")
//                 }
//                 for d in f.details.prefix(opts.maxFailureDetailLines) {
//                     out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))")
//                 }
//                 if f.details.count > opts.maxFailureDetailLines {
//                     out.append("    ↳ (+\(f.details.count - opts.maxFailureDetailLines) more)")
//                 }
//                 out.append("")
//             }
//             return out.joined(separator: "\n")
//         } else {
//             let df = ISO8601DateFormatter()
//             if opts.useISODateOnly { df.formatOptions = [.withFullDate] }

//             for it in items {
//                 // status line resembling failures style
//                 switch it.coverage {
//                 case .exact:
//                     out.append("match".ansi(.green))
//                 case .withinTolerance:
//                     out.append("match (±tol)".ansi(.green))
//                 case .aggregateCovered:
//                     out.append("aggregate covered".ansi(.green))
//                 case .none:
//                     out.append("mismatch".ansi(.yellow))
//                 }

//                 let period = "\(df.string(from: it.periodStart)) → \(df.string(from: it.periodEnd))"
//                 out.append("    • \(it.entity.identifier(displaying: .fullchain)) [\(it.account.code)]  \(period)")
//                 out.append("        expected: \(fmt(it.expected))")
//                 out.append("        got: \(fmt(it.actual))")
//                 out.append("        Δ = \(fmt(it.delta))")

//                 if let note = it.note, !note.isEmpty {
//                     out.append("    note: \(note)")
//                 }
//                 for d in it.details.prefix(opts.maxFailureDetailLines) {
//                     out.append("    ↳ entry \(d.entryId ?? "—")  \(df.string(from: d.date))  \(fmt(d.amount))")
//                 }
//                 if it.details.count > opts.maxFailureDetailLines {
//                     out.append("    ↳ (+\(it.details.count - opts.maxFailureDetailLines) more)")
//                 }
//                 out.append("")
//             }
//             return out.joined(separator: "\n")
//         }
//     }
// }
