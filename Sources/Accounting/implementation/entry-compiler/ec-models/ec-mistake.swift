import Foundation

public struct Resolvable: Hashable, Codable, Sendable {
    public var payable: Decimal?
    public var receivable: Decimal?

    public init(payable: Decimal? = nil, receivable: Decimal? = nil) {
        self.payable = payable
        self.receivable = receivable
    }
}

public struct Mistake: Hashable, Codable, Sendable {
    public var details: String?
    public var resolvable: Resolvable?

    public init(details: String? = nil, resolvable: Resolvable? = nil) {
        self.details = details
        self.resolvable = resolvable
    }
}

extension Mistake: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []

        if let d = details?.trimmingCharacters(in: .whitespacesAndNewlines), !d.isEmpty {
            parts.append("details: \"\(d)\"")
        }

        if let r = resolvable {
            var rparts: [String] = []
            if let p = r.payable { rparts.append("payable = \(Self.fmt(p))") }
            if let rc = r.receivable { rparts.append("receivable = \(Self.fmt(rc))") }
            if !rparts.isEmpty {
                parts.append("resolvable { \(rparts.joined(separator: ", ")) }")
            }
        }

        return parts.isEmpty ? "mistake {}" : "mistake { \(parts.joined(separator: " · ")) }"
    }

    private static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US_POSIX")
        nf.numberStyle = .decimal
        nf.usesGroupingSeparator = false
        nf.minimumFractionDigits = 0
        nf.maximumFractionDigits = 6
        return nf
    }()

    @inline(__always)
    private static func fmt(_ d: Decimal) -> String {
        let ns = NSDecimalNumber(decimal: d)
        return numberFormatter.string(from: ns) ?? ns.stringValue
    }
}
