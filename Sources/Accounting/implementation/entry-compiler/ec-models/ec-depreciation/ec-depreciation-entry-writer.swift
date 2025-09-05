import Foundation
import plate // SafeFile, SafeWriteOptions

public enum DepreciationEntryWriter {
    public struct Options: Sendable {
        public var tz: TimeZone
        public var tolerance: Decimal            // skip if rounded missing ≤ tolerance
        public var safe: SafeWriteOptions
        public var fractionDigits: Int           // NEW: rounding/formatting scale (default 2)

        public init(
            tz: TimeZone,
            tolerance: Decimal,
            safe: SafeWriteOptions,
            fractionDigits: Int = 2
        ) {
            self.tz = tz
            self.tolerance = tolerance
            self.safe = safe
            self.fractionDigits = fractionDigits
        }
    }

    @inline(__always)
    public static func roundDecimal(_ x: Decimal, scale: Int) -> Decimal {
        var v = x, out = Decimal()
        NSDecimalRound(&out, &v, scale, .plain) // half-up
        return out
    }

    @inline(__always)
    public static func fmtDecimal(_ x: Decimal, digits: Int) -> String {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US_POSIX")
        nf.numberStyle = .decimal
        nf.minimumFractionDigits = digits
        nf.maximumFractionDigits = digits
        nf.minimumIntegerDigits  = 1
        return nf.string(from: x as NSDecimalNumber) ?? x.description
    }

    /// - Returns: number of entries written (0 if nothing to write).
    public static func writeMissingForMonth(
        monthStart: Date,
        project: EntryCompilerProject,
        settings: EntryCompilerSettings,
        entities: EntityStore,
        report: DepreciationAuditReport,
        projectRoot: URL,
        options: Options,
        verbose: Bool = false
    ) throws -> Int {

        // Normalize the target month to [firstOfMonth, nextMonthStart)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = options.tz

        let comps = cal.dateComponents([.year, .month], from: monthStart)
        guard
            let firstOfMonth = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)),
            let nextMonthStart = cal.date(byAdding: .month, value: 1, to: firstOfMonth)
        else { return 0 }

        // Build entries/<year>/<quarter>/<month>/depreciation.ec
        let entriesRoot = projectRoot.appendingPathComponent("entries", isDirectory: true)
        let yqmMonth = try yqm(for: firstOfMonth, tz: options.tz)
        let targetPath = makeEntryPath(root: entriesRoot, yqm: yqmMonth, filename: "depreciation")

        // Seed global ID once (monotonic across entire project)
        var nextId = try IDScanner.suggestNextEntryID(project: project, settings: settings)
        @inline(__always) func allocID() -> Int { defer { nextId += 1 }; return nextId }

        var chunks: [String] = []
        chunks.reserveCapacity(report.items.count)

        for item in report.items {
            // Anchor to commission cadence: post on (periodEnd - 1 day)
            let rawPost = cal.date(byAdding: .day, value: -1, to: item.periodEnd) ?? item.periodEnd
            // Only write this item if its postDate falls inside the target month
            guard rawPost >= firstOfMonth && rawPost < nextMonthStart else { continue }

             // Only fill periods not covered by tol/quarter aggregation
             guard item.coverage == .none else { continue }

            // Missing amount: expected - actual → round first, then compare to tolerance
            let missingRaw = item.expected - item.actual
            let missing    = roundDecimal(missingRaw, scale: options.fractionDigits)
            guard missing > options.tolerance else { continue }

             // Pull resolved config; `contra` is non-optional in your branch
             guard let cfg = entities.byFull[item.entity]?.depreciation else { continue }

            let dateStr = isoDate(rawPost)

            let entityIdent = item.entity.identifier(displaying: .fullchain)
            let debitAccount = cfg.account.code
            let creditAccount = cfg.contra.code   // non-optional

            let monthLabel = "\(yqmMonth.year)-\(String(format: "%02d", yqmMonth.month))"
            let eid = allocID()

            let amt = fmtDecimal(missing, digits: options.fractionDigits)

            chunks.append("""
            entry {
                id = \(eid)

                date = \(dateStr)

                sort adjusting

                details { 
                    Depreciation \(entityIdent) \(monthLabel) 
                    Auto-generated
                }

                for (\(entityIdent)) in (\(debitAccount)) { 
                    debit = \(amt) 
                }

                for (\(entityIdent)) in (\(creditAccount)) { 
                    credit = \(amt) 
                }
            }
            """)
        }

        guard !chunks.isEmpty else { return 0 }

        // Make sure parent exists (independent of SafeWriteOptions.createIntermediateDirectories)
        try ensureDir(targetPath.deletingLastPathComponent())

        let header = "// AUTOGENERATED by ec depreciation --write for \(yqmMonth.year)-\(String(format: "%02d", yqmMonth.month))\n"
        let sf = SafeFile(targetPath) // init is unlabeled
        let writeResult = try sf.write(header + chunks.joined(separator: "\n\n"), options: options.safe)
        if verbose {
            print(writeResult)
        }

        return chunks.count
    }
}
