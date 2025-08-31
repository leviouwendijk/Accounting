import Foundation

public extension DepreciationConfig {
    func prettyDescription() -> String {
        let m   = schedule.method.canonical.rawValue
        let life = "\(fmt(schedule.usefulLifeYears)) years"
        let pct = fmt(residual.percentNormalized * 100) + "%"
        let amt = money(residual.amount)
        let eff = dateStr(schedule.effectiveDate)

        var lines: [String] = []
        lines.append("DepreciationConfig")
        lines.append("──────────────────")
        lines.append("• method            \(m)")
        lines.append("• useful life       \(life)")
        lines.append("• residual percent  \(pct)")
        lines.append("• residual amount   \(amt)")
        lines.append("• effective date    \(eff)")
        lines.append("• depreciable base  \(money(depreciableBase()))")

        return lines.joined(separator: "\n")
    }
}

// Make `print(config)` show the pretty one-liner by default.
extension DepreciationConfig: CustomStringConvertible {
    public var description: String { prettyDescription() }
}

// MARK: - Helpers (scoped private)
private func percentDisplay(_ p: Decimal) -> Decimal {
    // Accepts 0–1 or 0–100; display normalized to 0–100.
    let normalized = (p > 1) ? (p / 100) : p
    return normalized * 100
}

private func fmt(_ d: Decimal, maxFrac: Int = 2) -> String {
    let n = NSDecimalNumber(decimal: d)
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.minimumFractionDigits = 0
    f.maximumFractionDigits = maxFrac
    return f.string(from: n) ?? n.stringValue
}

private func money(_ d: Decimal, currency: String = "€", maxFrac: Int = 2) -> String {
    return currency + fmt(d, maxFrac: maxFrac)
}

private func dateStr(_ d: Date) -> String {
    // ISO date (yyyy-MM-dd) is snapshot-friendly
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withFullDate]
    return f.string(from: d)
}
