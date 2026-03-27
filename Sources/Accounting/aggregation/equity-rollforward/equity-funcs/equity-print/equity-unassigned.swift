import Foundation

@inlinable
public func unassignedEquityAmount(
    _ p: EquityPeriod,
    chart: CompiledChart,
    cfg: EquityRollforwardConfig
) -> Decimal? {
    let eqPrefix = cfg.equityTotalFallback ?? "BEiv"
    var sum: Decimal = 0

    if let byAcc = p.bundle.entity?.byAccount {
        for n in chart.nodes where n.codes.code.hasPrefix(eqPrefix) {
            if let v = byAcc[n.id]?[nil], v != 0 {
                sum += v
            }
        }
    }

    return sum == 0 ? nil : sum
}

@inlinable
public func debugUnassignedEquity(
    _ p: EquityPeriod,
    chart: CompiledChart,
    cfg: EquityRollforwardConfig
) {
    guard let sum = unassignedEquityAmount(
        p,
        chart: chart,
        cfg: cfg
    ) else {
        return
    }

    print("  · [debug] unassigned equity movements in \(p.label): \(sum)")
}

// @inlinable 
// public func printUnassignedEquityMovements(_ p: EquityPeriod, chart: CompiledChart, cfg: EquityRollforwardConfig) {
//     let maps = ChartMaps(chart: chart)
//     let eqPrefix = cfg.entity.equityPrefix ?? "BEiv"   // whatever you use in your config
//     var sum: Decimal = 0
//     if let byAcc = p.bundle.entity?.byAccount {
//         for n in chart.nodes where n.codes.code.hasPrefix(eqPrefix) {
//             if let m = byAcc[n.id], let v = m[nil] { sum += v }
//         }
//     }
//     if sum != 0 {
//         print("  · [debug] unassigned equity movements in \(p.label): \(sum)")
//     }
// }

// @inlinable 
// public func debugUnassignedEquity(_ p: EquityPeriod, chart: CompiledChart, cfg: EquityRollforwardConfig) {
//     let eqPrefix = cfg.equityTotalFallback ?? "BEiv"
//     var sum: Decimal = 0
//     if let byAcc = p.bundle.entity?.byAccount {
//         for n in chart.nodes where n.codes.code.hasPrefix(eqPrefix) {
//             if let v = byAcc[n.id]?[nil], v != 0 { sum += v }
//         }
//     }
//     if sum != 0 { print("  · [debug] unassigned equity movements in \(p.label): \(sum)") }
// }

