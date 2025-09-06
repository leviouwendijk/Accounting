import Foundation

// ─────────────────────────────────────────────────────────────────────────────
// Small utils & formatting

public enum PadAlign { case left, right }
public func pad(_ s: String, _ w: Int, _ a: PadAlign = .left) -> String {
    let len = s.count
    if len >= w { return s }
    let spaces = String(repeating: " ", count: w - len)
    return a == .left ? (s + spaces) : (spaces + s)
}
public func absD(_ x: Decimal) -> Decimal { x < 0 ? -x : x }
public func roundD(_ x: Decimal, digits: Int = 2) -> Decimal {
    var v = x, out = Decimal()
    NSDecimalRound(&out, &v, digits, .plain)
    return out
}
public func fmtDec(_ x: Decimal, digits: Int = 2) -> String {
    let nf = NumberFormatter()
    nf.locale = Locale(identifier: "nl_NL")
    nf.numberStyle = .decimal
    nf.minimumFractionDigits = digits
    nf.maximumFractionDigits = digits
    return nf.string(from: x as NSDecimalNumber) ?? x.description
}
public func fmtPct(_ p: Decimal, digits: Int = 2) -> String {
    "\(fmtDec(roundD(p * 100, digits: digits), digits: digits))%"
}

