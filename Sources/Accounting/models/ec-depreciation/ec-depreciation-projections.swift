import Foundation

public enum DepreciationGranularity: String, Codable, Sendable {
    case monthly, quarterly

    var stepMonths: Int {
        self == .monthly ? 1 : 3
    }
}

public enum DepreciationStartConvention: String, Codable, Sendable {
    case exactDate
    case startOfMonth
    case firstFullMonth
}

public struct DepreciationSlice: Codable, Sendable {
    public let periodStart: Date
    public let periodEnd: Date
    public let depreciation: Decimal
    public let nbvOpening: Decimal
    public let nbvClosing: Decimal
}

public extension DepreciationConfig {
    @inline(__always)
    func project(
        through endDate: Date,
        startDate: Date,
        startConvention: DepreciationStartConvention = .firstFullMonth,
        granularity: DepreciationGranularity = .monthly,
        calendar: Calendar = .init(identifier: .gregorian)
    ) -> [DepreciationSlice] {
        let lifeMonths = usefulLifeMonths
        guard lifeMonths > 0 else {
            return []
        }

        let acquisitionCost = acquistion.cost
        let residualAmount = residual.amount
        let base = depreciableBase()

        guard base > 0 else {
            return []
        }

        let start = depNormalizedStart(
            from: startDate,
            using: startConvention,
            calendar: calendar
        )

        let hardStop = depExclusiveHorizonEnd(
            for: endDate,
            calendar: calendar
        )

        guard start < hardStop else {
            return []
        }

        switch schedule.method {
        case .straight_line, .sl:
            let monthlySlices = depBuildStraightLineMonthlySlices(
                start: start,
                hardStop: hardStop,
                lifeMonths: lifeMonths,
                acquisitionCost: acquisitionCost,
                residualAmount: residualAmount,
                depreciableBase: base,
                calendar: calendar
            )

            switch granularity {
            case .monthly:
                return monthlySlices

            case .quarterly:
                return depAggregateMonthlySlicesIntoQuarterly(
                    monthlySlices,
                    hardStop: hardStop
                )
            }

        case .double_declining_balance, .ddb,
             .sum_of_year_digits, .syd,
             .units_of_production, .uop:
            return []
        }
    }
}

@inline(__always)
private func depMonthStart(
    for date: Date,
    calendar: Calendar
) -> Date {
    calendar.date(
        from: calendar.dateComponents([.year, .month], from: date)
    )!
}

@inline(__always)
private func depExclusiveHorizonEnd(
    for inclusiveEndDate: Date,
    calendar: Calendar
) -> Date {
    let startOfMonth = depMonthStart(
        for: inclusiveEndDate,
        calendar: calendar
    )

    return calendar.date(
        byAdding: .month,
        value: 1,
        to: startOfMonth
    )!
}

@inline(__always)
private func depNormalizedStart(
    from rawStart: Date,
    using convention: DepreciationStartConvention,
    calendar: Calendar
) -> Date {
    switch convention {
    case .exactDate:
        return rawStart

    case .startOfMonth:
        return depMonthStart(for: rawStart, calendar: calendar)

    case .firstFullMonth:
        let currentMonthStart = depMonthStart(
            for: rawStart,
            calendar: calendar
        )

        return calendar.date(
            byAdding: .month,
            value: 1,
            to: currentMonthStart
        )!
    }
}

private func depBuildStraightLineMonthlySlices(
    start: Date,
    hardStop: Date,
    lifeMonths: Int,
    acquisitionCost: Decimal,
    residualAmount: Decimal,
    depreciableBase: Decimal,
    calendar: Calendar
) -> [DepreciationSlice] {
    var slices: [DepreciationSlice] = []
    slices.reserveCapacity(lifeMonths)

    var previousCumulative = Decimal.zero

    for monthIndex in 1...lifeMonths {
        guard let periodStart = calendar.date(
            byAdding: .month,
            value: monthIndex - 1,
            to: start
        ) else {
            break
        }

        if periodStart >= hardStop {
            break
        }

        guard let periodEnd = calendar.date(
            byAdding: .month,
            value: 1,
            to: periodStart
        ) else {
            break
        }

        if periodEnd > hardStop {
            break
        }

        let currentCumulative = AccountingMoney.round(
            depreciableBase * Decimal(monthIndex) / Decimal(lifeMonths)
        )

        let depreciation = AccountingMoney.round(
            currentCumulative - previousCumulative
        )

        let nbvOpening = AccountingMoney.round(
            acquisitionCost - previousCumulative
        )

        let nbvClosing = max(
            residualAmount,
            AccountingMoney.round(acquisitionCost - currentCumulative)
        )

        slices.append(
            .init(
                periodStart: periodStart,
                periodEnd: periodEnd,
                depreciation: depreciation,
                nbvOpening: nbvOpening,
                nbvClosing: nbvClosing
            )
        )

        previousCumulative = currentCumulative
    }

    return slices
}

private func depAggregateMonthlySlicesIntoQuarterly(
    _ monthlySlices: [DepreciationSlice],
    hardStop: Date
) -> [DepreciationSlice] {
    guard monthlySlices.count >= 3 else {
        return []
    }

    var out: [DepreciationSlice] = []
    out.reserveCapacity(monthlySlices.count / 3)

    var index = 0

    while index + 2 < monthlySlices.count {
        let bucket = Array(monthlySlices[index..<(index + 3)])
        let start = bucket[0].periodStart
        let end = bucket[2].periodEnd

        if end > hardStop {
            break
        }

        let depreciation = AccountingMoney.round(
            bucket.reduce(Decimal.zero) { partial, slice in
                partial + slice.depreciation
            }
        )

        out.append(
            .init(
                periodStart: start,
                periodEnd: end,
                depreciation: depreciation,
                nbvOpening: bucket[0].nbvOpening,
                nbvClosing: bucket[2].nbvClosing
            )
        )

        index += 3
    }

    return out
}

// public enum DepreciationGranularity: String, Codable, Sendable {
//     case monthly, quarterly

//     var stepMonths: Int {
//         self == .monthly ? 1 : 3
//     }
// }

// public enum DepreciationStartConvention: String, Codable, Sendable {
//     case exactDate
//     case startOfMonth
//     case firstFullMonth
// }

// public struct DepreciationSlice: Codable, Sendable {
//     public let periodStart: Date
//     public let periodEnd: Date
//     public let depreciation: Decimal
//     public let nbvOpening: Decimal
//     public let nbvClosing: Decimal
// }

// // experimental fix:
// public extension DepreciationConfig {
//     @inline(__always)
//     func project(
//         through endDate: Date,
//         startDate: Date,
//         startConvention: DepreciationStartConvention = .firstFullMonth,
//         granularity: DepreciationGranularity = .monthly,
//         calendar: Calendar = .init(identifier: .gregorian)
//     ) -> [DepreciationSlice] {
//         let lifeMonths = usefulLifeMonths
//         guard lifeMonths > 0 else {
//             return []
//         }

//         let base = depreciableBase()
//         var slices: [DepreciationSlice] = []

//         @inline(__always)
//         func endOf(_ start: Date, step: Int) -> Date {
//             calendar.date(byAdding: .month, value: step, to: start)!
//         }

//         @inline(__always)
//         func monthStart(for date: Date) -> Date {
//             calendar.date(
//                 from: calendar.dateComponents([.year, .month], from: date)
//             )!
//         }

//         @inline(__always)
//         func exclusiveHorizonEnd(for inclusiveEndDate: Date) -> Date {
//             let startOfMonth = monthStart(for: inclusiveEndDate)
//             return calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
//         }

//         @inline(__always)
//         func normalizedStart(
//             from rawStart: Date,
//             using convention: DepreciationStartConvention
//         ) -> Date {
//             switch convention {
//             case .exactDate:
//                 return rawStart

//             case .startOfMonth:
//                 return monthStart(for: rawStart)

//             case .firstFullMonth:
//                 let startOfCurrentMonth = monthStart(for: rawStart)
//                 return calendar.date(
//                     byAdding: .month,
//                     value: 1,
//                     to: startOfCurrentMonth
//                 )!
//             }
//         }

//         let start = normalizedStart(
//             from: startDate,
//             using: startConvention
//         )

//         let hardStop = exclusiveHorizonEnd(
//             for: endDate
//         )

//         guard start < hardStop else {
//             return []
//         }

//         switch schedule.method {
//         case .straight_line, .sl:
//             let monthly = base / Decimal(lifeMonths)
//             var nbv = acquistion.cost
//             var curStart = start

//             while curStart < hardStop && slices.count < 10_000 {
//                 let naturalEnd = endOf(
//                     curStart,
//                     step: granularity.stepMonths
//                 )

//                 if naturalEnd > hardStop {
//                     break
//                 }

//                 let dep = max(
//                     0,
//                     monthly * Decimal(granularity.stepMonths)
//                 )

//                 let closing = max(
//                     residual.amount,
//                     nbv - dep
//                 )

//                 slices.append(
//                     .init(
//                         periodStart: curStart,
//                         periodEnd: naturalEnd,
//                         depreciation: dep,
//                         nbvOpening: nbv,
//                         nbvClosing: closing
//                     )
//                 )

//                 nbv = closing
//                 curStart = naturalEnd

//                 if nbv <= residual.amount {
//                     break
//                 }
//             }

//         case .double_declining_balance, .ddb,
//              .sum_of_year_digits, .syd,
//              .units_of_production, .uop:
//             break
//         }

//         return slices
//     }
// }
