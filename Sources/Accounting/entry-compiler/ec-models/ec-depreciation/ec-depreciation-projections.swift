import Foundation

public enum DepreciationGranularity: String, Codable, Sendable {
    case monthly, quarterly
    var stepMonths: Int { self == .monthly ? 1 : 3 }
}

public struct DepreciationSlice: Codable, Sendable {
    public let periodStart: Date
    public let periodEnd: Date
    public let depreciation: Decimal
    public let nbvOpening: Decimal
    public let nbvClosing: Decimal
}

// experimental fix:
public extension DepreciationConfig {
    func project(
        through endDate: Date,
        granularity: DepreciationGranularity = .monthly,
        calendar: Calendar = .init(identifier: .gregorian)
    ) -> [DepreciationSlice] {
        let lifeMonths = usefulLifeMonths
        guard lifeMonths > 0 else { return [] }

        let start = schedule.effectiveDate
        let base = depreciableBase()
        var slices: [DepreciationSlice] = []

        func endOf(_ start: Date, step: Int) -> Date {
            calendar.date(byAdding: .month, value: step, to: start)!
        }

        @inline(__always)
        func monthStart(for date: Date) -> Date {
            calendar.date(
                from: calendar.dateComponents([.year, .month], from: date)
            )!
        }

        @inline(__always)
        func exclusiveHorizonEnd(for inclusiveEndDate: Date) -> Date {
            let startOfMonth = monthStart(for: inclusiveEndDate)
            return calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        }

        switch schedule.method {
        case .straight_line, .sl:
            let monthly = base / Decimal(lifeMonths)
            var nbv = acquistion.cost
            var curStart = start

            let hardStop = exclusiveHorizonEnd(for: endDate)

            while curStart < hardStop && slices.count < 10_000 {
                let naturalEnd = endOf(curStart, step: granularity.stepMonths)

                // Do not emit truncated tail slices.
                if naturalEnd > hardStop {
                    break
                }

                let dep = max(0, monthly * Decimal(granularity.stepMonths))
                let closing = max(residual.amount, nbv - dep)

                slices.append(
                    .init(
                        periodStart: curStart,
                        periodEnd: naturalEnd,
                        depreciation: dep,
                        nbvOpening: nbv,
                        nbvClosing: closing
                    )
                )

                nbv = closing
                curStart = naturalEnd

                if nbv <= residual.amount {
                    break
                }
            }

        case .double_declining_balance, .ddb,
             .sum_of_year_digits, .syd,
             .units_of_production, .uop:
            break
        }

        return slices
    }
}

// ROLLBACK ON REGRESSIONS:

// public extension DepreciationConfig {
//     func project(
//         through endDate: Date,
//         granularity: DepreciationGranularity = .monthly,
//         calendar: Calendar = .init(identifier: .gregorian)
//     ) -> [DepreciationSlice] {
//         let lifeMonths = usefulLifeMonths
//         guard lifeMonths > 0 else { return [] }

//         let start = schedule.effectiveDate
//         let base = depreciableBase()
//         var slices: [DepreciationSlice] = []

//         func endOf(_ start: Date, step: Int) -> Date {
//             calendar.date(byAdding: .month, value: step, to: start)!
//         }

//         switch schedule.method {
//         case .straight_line, .sl:
//             // simple: even per month
//             let monthly = base / Decimal(lifeMonths)
//             var nbv = acquistion.cost
//             var curStart = start

//             while curStart < endDate && slices.count < 10_000 {
//                 let curEnd = min(endOf(curStart, step: granularity.stepMonths), endDate)
//                 let monthsInSlice = calendar.dateComponents([.month], from: curStart, to: curEnd).month ?? 0
//                 let dep = max(0, monthly * Decimal(monthsInSlice))
//                 let closing = max(residual.amount, nbv - dep)
//                 slices.append(.init(periodStart: curStart, periodEnd: curEnd,
//                                     depreciation: dep, nbvOpening: nbv, nbvClosing: closing))
//                 nbv = closing
//                 curStart = curEnd
//                 if nbv <= residual.amount { break }
//             }

//         case .double_declining_balance, .ddb,
//              .sum_of_year_digits, .syd,
//              .units_of_production, .uop:
//             break
//         }
//         return slices
//     }
// }
