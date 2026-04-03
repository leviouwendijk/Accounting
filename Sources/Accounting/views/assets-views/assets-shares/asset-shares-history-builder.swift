import Foundation

public extension AssetViews {
    enum AssetSharesHistoryBuilder {
        public static func build(
            result: EntryCompileDriver.Result,
            kind: PeriodKind,
            anchor: Date,
            customFrom: Date?,
            customTo: Date?,
            includeHistory: Bool,
            calendar: Calendar
        ) throws -> AssetSharesHistoryReport {
            if includeHistory && kind == .year {
                let periods = try buildHistoricalYearPeriods(
                    result: result,
                    anchor: anchor,
                    calendar: calendar
                )

                return AssetSharesHistoryReport(
                    title: "Aandelen in activa",
                    periods: periods
                )
            }

            let windows = PeriodSlicer.resolve(
                shape: .init(
                    kind: kind,
                    rangeToDate: false
                ),
                anchor: anchor,
                customFrom: customFrom,
                customTo: customTo,
                calendar: calendar
            )

            let period = try makePeriodReport(
                result: result,
                period: windows.window,
                calendar: calendar
            )

            return AssetSharesHistoryReport(
                title: "Aandelen in activa",
                periods: [period]
            )
        }

        private static func buildHistoricalYearPeriods(
            result: EntryCompileDriver.Result,
            anchor: Date,
            calendar: Calendar
        ) throws -> [AssetSharesPeriodReport] {
            let resolvedDates = result.resolved.compactMap { resolved in
                absDate(resolved.date)
            }

            let anchorYear = calendar.component(.year, from: anchor)

            guard let earliest = resolvedDates.min() else {
                return [
                    try makePeriodReport(
                        result: result,
                        period: yearWindow(
                            year: anchorYear,
                            calendar: calendar
                        ),
                        calendar: calendar
                    )
                ]
            }

            let earliestYear = calendar.component(.year, from: earliest)
            let startYear = min(earliestYear, anchorYear)

            return try (startYear...anchorYear).map { year in
                try makePeriodReport(
                    result: result,
                    period: yearWindow(
                        year: year,
                        calendar: calendar
                    ),
                    calendar: calendar
                )
            }
        }

        private static func makePeriodReport(
            result: EntryCompileDriver.Result,
            period: PeriodWindow,
            calendar: Calendar
        ) throws -> AssetSharesPeriodReport {
            let overview = try AssetsOverviewBuilder.build(
                result: result,
                period: period,
                calendar: calendar
            )

            let summary = AssetViews.AssetsOverviewSharesSummary.visible(
                from: overview
            )

            return AssetSharesPeriodReport(
                period: overview.period,
                openingCarryingAmount: summary.openingCarryingAmount,
                periodInvestment: summary.periodInvestment,
                closingCarryingAmount: summary.closingCarryingAmount,
                breakdown: summary.breakdown
            )
        }

        private static func yearWindow(
            year: Int,
            calendar: Calendar
        ) -> PeriodWindow {
            let from = calendar.date(
                from: DateComponents(
                    year: year,
                    month: 1,
                    day: 1
                )
            )

            let to = calendar.date(
                from: DateComponents(
                    year: year,
                    month: 12,
                    day: 31,
                    hour: 23,
                    minute: 59,
                    second: 59
                )
            )

            return .init(
                from: from,
                to: to
            )
        }
    }
}

// public extension AssetViews {
//     enum AssetSharesHistoryBuilder {
//         public static func build(
//             result: EntryCompileDriver.Result,
//             kind: PeriodKind,
//             anchor: Date,
//             customFrom: Date?,
//             customTo: Date?,
//             includeHistory: Bool,
//             tz: TimeZone,
//             calendar base: Calendar
//         ) throws -> AssetSharesHistoryReport {
//             var calendar = base
//             calendar.timeZone = tz

//             if includeHistory && kind == .year {
//                 let periods = try buildHistoricalYearPeriods(
//                     result: result,
//                     anchor: anchor,
//                     calendar: calendar
//                 )

//                 return AssetSharesHistoryReport(
//                     title: "Aandelen in activa",
//                     periods: periods
//                 )
//             }

//             let windows = PeriodSlicer.resolve(
//                 shape: .init(
//                     kind: kind,
//                     rangeToDate: false
//                 ),
//                 anchor: anchor,
//                 customFrom: customFrom,
//                 customTo: customTo,
//                 tz: tz,
//                 calendar: calendar
//             )

//             let period = try makePeriodReport(
//                 result: result,
//                 period: windows.window,
//                 calendar: calendar
//             )

//             return AssetSharesHistoryReport(
//                 title: "Aandelen in activa",
//                 periods: [period]
//             )
//         }

//         private static func buildHistoricalYearPeriods(
//             result: EntryCompileDriver.Result,
//             anchor: Date,
//             calendar: Calendar
//         ) throws -> [AssetSharesPeriodReport] {
//             let resolvedDates = result.resolved.compactMap { resolved in
//                 absDate(resolved.date)
//             }

//             let anchorYear = calendar.component(.year, from: anchor)

//             guard let earliest = resolvedDates.min() else {
//                 return [
//                     try makePeriodReport(
//                         result: result,
//                         period: yearWindow(
//                             year: anchorYear,
//                             // anchor: anchor,
//                             calendar: calendar
//                         ),
//                         calendar: calendar
//                     )
//                 ]
//             }

//             let earliestYear = calendar.component(.year, from: earliest)
//             let startYear = min(earliestYear, anchorYear)

//             return try (startYear...anchorYear).map { year in
//                 try makePeriodReport(
//                     result: result,
//                     period: yearWindow(
//                         year: year,
//                         // anchor: anchor,
//                         calendar: calendar
//                     ),
//                     calendar: calendar
//                 )
//             }
//         }

//         private static func makePeriodReport(
//             result: EntryCompileDriver.Result,
//             period: PeriodWindow,
//             calendar: Calendar
//         ) throws -> AssetSharesPeriodReport {
//             let overview = try AssetsOverviewBuilder.build(
//                 result: result,
//                 period: period,
//                 calendar: calendar
//             )

//             let summary = AssetViews.AssetsOverviewSharesSummary.visible(
//                 from: overview
//             )

//             return AssetSharesPeriodReport(
//                 period: overview.period,
//                 openingCarryingAmount: summary.openingCarryingAmount,
//                 periodInvestment: summary.periodInvestment,
//                 closingCarryingAmount: summary.closingCarryingAmount,
//                 breakdown: summary.breakdown
//             )
//         }

//         private static func yearWindow(
//             year: Int,
//             calendar: Calendar
//         ) -> PeriodWindow {
//             let from = calendar.date(
//                 from: DateComponents(
//                     year: year,
//                     month: 1,
//                     day: 1
//                 )
//             )

//             let to = calendar.date(
//                 from: DateComponents(
//                     year: year,
//                     month: 12,
//                     day: 31
//                 )
//             ).map { date in
//                 var comps = calendar.dateComponents(
//                     [.year, .month, .day],
//                     from: date
//                 )
//                 comps.hour = 23
//                 comps.minute = 59
//                 comps.second = 59
//                 return calendar.date(from: comps) ?? date
//             }

//             return PeriodWindow(
//                 from: from,
//                 to: to
//             )
//         }

//         private static func dayEnd(
//             _ date: Date,
//             calendar: Calendar
//         ) -> Date {
//             var comps = calendar.dateComponents(
//                 [.year, .month, .day],
//                 from: date
//             )
//             comps.hour = 23
//             comps.minute = 59
//             comps.second = 59
//             return calendar.date(from: comps) ?? date
//         }
//     }
// }
