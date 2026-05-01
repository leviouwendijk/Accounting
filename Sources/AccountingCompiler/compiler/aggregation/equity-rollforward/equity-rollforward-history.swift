import Accounting
import Foundation

extension OwnerEquity.Rollforward {
    // public func runOwnerEquityRollforwardHistory(
    public static func history(
        title: String = "Equity rollforward (backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>?,
        config cfg: EquityRollforwardConfig = .init(),
        afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
    ) throws {
        // let report = try buildOwnerEquityRollforwardReport(
        let report = try Self.report(
            title: title,
            allPeriods: allPeriods,
            chart: chart,
            entities: entities,
            view: view,
            config: cfg
        )

        printHeader(report.title)

        guard !report.periods.isEmpty else {
            print("(no periods)")
            return
        }

        for msg in report.anchorMessages {
            print(msg)
        }

        Self.printDiagnostics(report.diagnostics, entities: entities)

        let renderedPeriods: [EquityPeriod]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            renderedPeriods = Array(allPeriods[clampedLower...clampedUpper])
        } else {
            renderedPeriods = allPeriods
        }

        for (period, rendered) in zip(renderedPeriods, report.periods) {
            printPeriod(
                label: rendered.label,
                rows: rendered.rows,
                entities: entities,
                cfg: cfg
            )

            afterEachPeriod?(
                period,
                rendered.rows.owners,
                rendered.rows.deltas,
                cfg
            )
        }
    }

    // public func runOwnerEquityRollforwardHistoryAsync(
    public static func history_async(
        title: String = "Equity rollforward (backsolved)",
        allPeriods: [EquityPeriod],
        chart: CompiledChart,
        entities: EntityStore,
        view: ClosedRange<Int>?,
        config cfg: EquityRollforwardConfig = .init(),
        afterEachPeriod: ((EquityPeriod, [Int], [Int: OwnerDelta], EquityRollforwardConfig) -> Void)? = nil
    ) async throws {
        // let report = try await buildOwnerEquityRollforwardReportAsync(
        let report = try await report_async(
            title: title,
            allPeriods: allPeriods,
            chart: chart,
            entities: entities,
            view: view,
            config: cfg
        )

        printHeader(report.title)

        guard !report.periods.isEmpty else {
            print("(no periods)")
            return
        }

        for msg in report.anchorMessages {
            print(msg)
        }

        Self.printDiagnostics(report.diagnostics, entities: entities)

        let renderedPeriods: [EquityPeriod]
        if let viewRange = view {
            let clampedLower = max(viewRange.lowerBound, allPeriods.startIndex)
            let clampedUpper = min(viewRange.upperBound, allPeriods.endIndex - 1)
            renderedPeriods = Array(allPeriods[clampedLower...clampedUpper])
        } else {
            renderedPeriods = allPeriods
        }

        for (period, rendered) in zip(renderedPeriods, report.periods) {
            printPeriod(
                label: rendered.label,
                rows: rendered.rows,
                entities: entities,
                cfg: cfg
            )

            afterEachPeriod?(
                period,
                rendered.rows.owners,
                rendered.rows.deltas,
                cfg
            )
        }
    }
}

extension OwnerEquity.Rollforward {
    public static func history_from_inception(
        entries: [Entry],
        endAsOf: Date,
        kind: PeriodKind,
        calendar: Calendar,
        settings: EntryCompilerSettings,
        assemble: (_ periodStart: Date, _ periodEndExcl: Date) throws -> StatementBundle
    ) throws -> [EquityPeriod] {
        // Lifetime → single bucket (inception…endAsOf)
        if kind == .lifetime {
            let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
            let start = calendar.startOfDay(for: inception)
            let endExcl = nextPeriodStart(after: periodStart(for: endAsOf, kind: .month, calendar: calendar), // put it in next midnight
                                          kind: .month, calendar: calendar)
            let b = try assemble(start, endExcl)
            return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
        }

        // Align inception to period boundary
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

        // End: make sure the last period contains endAsOf
        let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
        let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

        var out: [EquityPeriod] = []
        while curStart < hardStop {
            let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
            let endExcl = min(nextStart, hardStop)
            let bundle = try assemble(curStart, endExcl)
            out.append(.init(
                label: labelForPeriodStart(curStart, kind: kind, calendar: calendar),
                bundle: bundle,
                asOf: calendar.date(byAdding: .second, value: -1, to: endExcl) ?? endExcl
            ))
            curStart = nextStart
        }
        return out
    }

    public static func history_from_inception_async(
        entries: [Entry],
        endAsOf: Date,
        kind: PeriodKind,
        calendar: Calendar,
        settings: EntryCompilerSettings,
        assemble_async: @escaping @Sendable (_ periodStart: Date, _ periodEndExcl: Date) async throws -> StatementBundle
    ) async throws -> [EquityPeriod] {
        // Lifetime → single bucket (inception…endAsOf)
        if kind == .lifetime {
            let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
            let start = calendar.startOfDay(for: inception)
            let endExcl = nextPeriodStart(
                after: periodStart(for: endAsOf, kind: .month, calendar: calendar),
                kind: .month,
                calendar: calendar
            )
            let b = try await assemble_async(start, endExcl)
            return [.init(label: "lifetime", bundle: b, asOf: endAsOf)]
        }

        // Non-lifetime: walk discrete periods from inception → endAsOf
        let inception = try earliestAbsoluteDate(entries: entries, settings: settings)
        var curStart = periodStart(for: inception, kind: kind, calendar: calendar)

        let anchorStartForEnd = periodStart(for: endAsOf, kind: kind, calendar: calendar)
        let hardStop = nextPeriodStart(after: anchorStartForEnd, kind: kind, calendar: calendar)

        struct Slice {
            let index: Int
            let start: Date
            let endExcl: Date
            let label: String
            let asOf: Date
        }

        var slices: [Slice] = []
        var idx = 0

        while curStart < hardStop {
            let nextStart = nextPeriodStart(after: curStart, kind: kind, calendar: calendar)
            let endExcl = min(nextStart, hardStop)

            let label = labelForPeriodStart(curStart, kind: kind, calendar: calendar)

            // as-of = last day within [curStart, endAsOf], inclusive
            let asOf: Date = {
                if endExcl > endAsOf {
                    return endAsOf
                } else {
                    // endExcl is start of next period → use previous day
                    return calendar.date(byAdding: .day, value: -1, to: endExcl) ?? endExcl
                }
            }()

            slices.append(.init(index: idx, start: curStart, endExcl: endExcl, label: label, asOf: asOf))
            curStart = nextStart
            idx += 1
        }

        if slices.isEmpty { return [] }

        // Parallel assemble per-period bundles
        var out = Array<EquityPeriod?>(repeating: nil, count: slices.count)

        try await withThrowingTaskGroup(of: (Int, EquityPeriod).self) { group in
            for s in slices {
                group.addTask { [s, assemble_async] in
                    let bundle = try await assemble_async(s.start, s.endExcl)
                    let period = EquityPeriod(label: s.label, bundle: bundle, asOf: s.asOf)
                    return (s.index, period)
                }
            }

            for try await (i, p) in group {
                out[i] = p
            }
        }

        return out.compactMap { $0 }
    }
}
