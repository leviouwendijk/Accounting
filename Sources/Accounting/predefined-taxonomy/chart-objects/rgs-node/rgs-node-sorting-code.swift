import Foundation

public struct RGSNodeSortingCode: Sendable, Codable, Hashable {
    public let segments: [String]

    public var key: String { 
        segments.joined(separator: ".") 
    }

    public init(segments: [String]) {
        self.segments = segments
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }

    public init(key: String) {
        self.segments = key
        .split(separator: ".", omittingEmptySubsequences: true)
        .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    }

    @inlinable
    public func isConsistent(withExcelLevel level: UInt8) -> Bool {
        xlsxImpliedLevel == Int(level)
    }

    /// Excel mapping — calibrated to observed sheet:
    /// - Base = min(segments.count, 3) + 1
    /// - If there are exactly 2 segments and the 2nd is LETTERS + ≥2 digits (e.g. "A010"),
    ///   bump to level 4.
    /// - If there are ≥3 segments:
    ///     * Consider ONLY the 3rd segment for bumping.
    ///     * Bump to level 5 iff the 3rd segment is LETTERS + ≥2 digits
    ///       AND its letter prefix equals the 1st OR 2nd segment (family match).
    ///     * Digits-only (e.g. "010") never bumps.
    @inlinable
    public var xlsxImpliedLevel: Int {
        let segs = segments
        let segCount = segs.count
        let hierDepth = min(segCount, 3)
        var implied = hierDepth + 1

        // 2-segment compression like "I.A010" should be level 4
        if segCount == 2 {
            let second = segs[1]
            if second.range(of: #"^[A-Z]+[0-9]{2,}$"#, options: .regularExpression) != nil {
                implied = 4
            }
            return implied
        }

        // 3+ segments: optional bump to 5 based on the 3rd token
        if hierDepth == 3 {
            let third = segs[2]

            // digits-only never bumps
            guard third.range(of: #"^[0-9]+$"#, options: .regularExpression) == nil else {
                return implied // stay at 4
            }

            // letters + >=2 digits?
            guard third.range(of: #"^[A-Z]+[0-9]{2,}$"#, options: .regularExpression) != nil else {
                return implied // stay at 4
            }

            // Extract the letter prefix of the third token (e.g. "A" from "A010", "AA" from "AA10")
            let letterPrefix = String(third.prefix { ($0 >= "A" && $0 <= "Z") })

            // Bump only if that prefix equals the 1st or 2nd segment (family match)
            if segs.indices.contains(0), letterPrefix == segs[0] { implied = 5 }
            else if segs.indices.contains(1), letterPrefix == segs[1] { implied = 5 }
        }

        return implied
    }

    @inlinable 
    public var parentKeyString: String? {
        guard segments.count > 1 else { return nil }
        return segments.dropLast().joined(separator: ".")
    }

    /// l2Key for links: use first two segments if present,
    /// else the single segment if present,
    /// else fall back to side ("B"/"W") derived from the code.
    @inlinable 
    public func l2Key(fallbackSide: String) -> String {
        if segments.count >= 2 { return segments.prefix(2).joined(separator: ".") }
        if segments.count == 1 { return segments[0] }
        return fallbackSide
    }

    /// SOFT checker: returns nil when consistent; otherwise a detailed multi-line report.
    /// Pass `implied:` if you already computed `xlsxImpliedLevel` and want to reuse it.
    @inlinable
    public func softConsistencyReport(
        expectedLevel level: UInt8,
        code: String? = nil,
        implied precomputed: Int? = nil
    ) -> String? {
        let implied = precomputed ?? xlsxImpliedLevel
        if implied == Int(level) { return nil }

        let segs = segments
        let segCount = segs.count
        let hierDepth = min(segCount, 3)

        var bumpNote = ""
        if hierDepth == 3 {
            let third = segs[2]
            let lettersPlus2Digits =
                third.range(of: #"^[A-Z]+[0-9]{2,}$"#, options: .regularExpression) != nil
            if lettersPlus2Digits { bumpNote = " (+ bump→5)" }
        }

        var lines: [String] = []
        lines.append(code != nil
            ? "RGS soft check for \(code!): Excel level \(level) vs implied \(implied)."
            : "RGS soft check: Excel level \(level) vs implied \(implied).")
        lines.append("  Sortering.key = \"\(key)\"")
        lines.append("  segments = \(segs) (count=\(segCount))")
        lines.append("  parentKey = \(parentKeyString ?? "nil")")
        lines.append("  hierDepth = min(count,3) = \(hierDepth); rule: implied = hierDepth + 1\(bumpNote)")

        return lines.joined(separator: "\n")
    }
}
