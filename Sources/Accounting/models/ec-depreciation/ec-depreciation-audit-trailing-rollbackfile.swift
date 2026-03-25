// ROLLBCCK:
// import Foundation

// public enum DepreciationCoverage: String, Codable, Sendable {
//     case exact, withinTolerance, aggregateCovered, none
// }

// public struct DepreciationMatchDetail: Codable, Sendable {
//     public let entryId: String?
//     public let date: Date
//     public let amount: Decimal
// }

// public struct DepreciationAuditItem: Codable, Sendable {
//     public let entity: EntityKey
//     public let account: AccountKey
//     public let periodStart: Date
//     public let periodEnd: Date
//     public let expected: Decimal
//     public let actual: Decimal
//     public let delta: Decimal
//     public let coverage: DepreciationCoverage
//     public let details: [DepreciationMatchDetail]
//     public let note: String?
// }

// public struct DepreciationAuditReport: Codable, Sendable {
//     public let items: [DepreciationAuditItem]
//     public let tolerance: Decimal

//     public var failures: [DepreciationAuditItem] {
//         items.filter { $0.coverage == .none }
//     }
// }

// private struct QKey: Hashable { 
//     let y: Int 
//     let q: Int 
    
//     public init(
//         y: Int,
//         q: Int
//     ) {
//         self.y = y
//         self.q = q
//     }
// }

// public extension Array where Element == ResolvedEntry {

//     /// Audit projected depreciation vs. postings in these resolved entries.
//     ///
//     /// - projections: expected per-entity slices (e.g. from EntityStore.projectDepreciation).
//     /// - configs:     resolved configs (for the posting account used by each entity).
//     /// - dateOf:      how to extract a `Date` from a `ResolvedEntry` (handles DateSpecification cases).
//     func auditDepreciation(
//         projections: [EntityKey: [DepreciationSlice]],
//         configs: [EntityKey: DepreciationConfig],
//         granularity: DepreciationGranularity,
//         calendar: Calendar = .init(identifier: .gregorian),
//         tolerance: Decimal = 0.01,
//         tolerateAggregateIntraQuarter: Bool = true,
//         dateOf: (ResolvedEntry) -> Date
//     ) -> DepreciationAuditReport {

//         var items: [DepreciationAuditItem] = []

//         // func qkey(_ d: Date) -> QKey {
//         //     let c = calendar.dateComponents([.year, .month], from: d)
//         //     let m = (c.month ?? 1)
//         //     return QKey(y: c.year ?? 1970, q: ((m - 1) / 3) + 1)
//         // }

//         func qkey(_ d: Date) -> QKey {
//             let c = calendar.dateComponents([.year, .month], from: d)
//             let m = (c.month ?? 1)
//             return QKey(y: c.year ?? 1970, q: ((m - 1) / 3) + 1)
//         }

//         func qkey(for slice: DepreciationSlice) -> QKey {
//             let postingDate = calendar.date(byAdding: .day, value: -1, to: slice.periodEnd) ?? slice.periodEnd
//             return qkey(postingDate)
//         }

//         var quarterExpected: [QKey: Decimal] = [:]
//         var quarterActual:   [QKey: Decimal] = [:]

//         for (ekey, slices) in projections {
//             guard let cfg = configs[ekey] else { continue }
//             let account = cfg.account

//             // Precompute quarter sums
//             if granularity == .monthly || granularity == .quarterly {
//                 // for s in slices {
//                 //     quarterExpected[qkey(s.periodStart), default: 0] += s.depreciation
//                 //     let (act, _) = sumForPeriod(
//                 //         entity: ekey, account: account,
//                 //         from: s.periodStart, to: s.periodEnd,
//                 //         dateOf: dateOf
//                 //     )
//                 //     quarterActual[qkey(s.periodStart), default: 0] += act
//                 // }
//                 for s in slices {
//                     let k = qkey(for: s)
//                     quarterExpected[k, default: 0] += s.depreciation
//                     let (act, _) = sumForPeriod(
//                         entity: ekey, account: account,
//                         from: s.periodStart, to: s.periodEnd,
//                         dateOf: dateOf
//                     )
//                     quarterActual[k, default: 0] += act
//                 }
//             }

//             // Per-slice details
//             for s in slices {
//                 let (actual, details) = sumForPeriod(
//                     entity: ekey, account: account,
//                     from: s.periodStart, to: s.periodEnd,
//                     dateOf: dateOf
//                 )

//                 let expected = s.depreciation
//                 let delta = (actual - expected).magnitude

//                 var coverage: DepreciationCoverage
//                 var note: String? = nil

//                 if delta == 0 {
//                     coverage = .exact
//                 } else if delta <= tolerance {
//                     coverage = .withinTolerance
//                 } else if granularity == .monthly && tolerateAggregateIntraQuarter {
//                     // let k = qkey(s.periodStart)
//                     let k = qkey(for: s)
//                     if let qExp = quarterExpected[k], let qAct = quarterActual[k],
//                        (qAct - qExp).magnitude <= tolerance {
//                         coverage = .aggregateCovered
//                         note = "Quarter total matches; month differs but covered by quarter-end booking."
//                     } else {
//                         coverage = .none
//                     }
//                 } else {
//                     coverage = .none
//                 }

//                 items.append(DepreciationAuditItem(
//                     entity: ekey,
//                     account: account,
//                     periodStart: s.periodStart,
//                     periodEnd: s.periodEnd,
//                     expected: expected,
//                     actual: actual,
//                     delta: (actual - expected),
//                     coverage: coverage,
//                     details: details,
//                     note: note
//                 ))
//             }
//         }

//         return DepreciationAuditReport(items: items, tolerance: tolerance)
//     }

//     // Sum entity+account postings for [from, to), with details
//     private func sumForPeriod(
//         entity: EntityKey,
//         account: AccountKey,
//         from: Date,
//         to: Date,
//         dateOf: (ResolvedEntry) -> Date
//     ) -> (Decimal, [DepreciationMatchDetail]) {

//         var sum: Decimal = 0
//         var details: [DepreciationMatchDetail] = []

//         for e in self {
//             let d = dateOf(e)
//             if d < from || d >= to { continue }

//             for l in e.lines where l.entity == entity && l.account == account {
//                 let amt = l.amount.magnitude   // ignore sign for comparison
//                 sum += amt
//                 details.append(.init(entryId: entryIdString(e), date: d, amount: amt))
//             }
//         }
//         return (sum, details)
//     }
// }

// private func entryIdString(_ e: ResolvedEntry) -> String? {
//     return String(describing: e.id)
// }
