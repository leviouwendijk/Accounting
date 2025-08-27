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

    // @inlinable
    // public var xlsxImpliedLevel: Int {
    //     let segs = segments
    //     let hierDepth = min(segs.count, 3)
    //     var implied = hierDepth + 1

    //     if hierDepth == 3 {
    //         let last = segs[2]
    //         let hasLeadingLetters = last.range(of: #"^[A-Z]+"#, options: .regularExpression) != nil
    //         if hasLeadingLetters, let r = last.range(of: #"[0-9]+$"#, options: .regularExpression) {
    //             let digitsCount = last[r].count
    //             if digitsCount > 1 { implied += 1 } // 5
    //         }
    //     }

    //     return implied
    // }

    @inlinable
    public var xlsxImpliedLevel: Int {
        let segs = segments
        let n = segs.count
        var implied = min(n, 3) + 1

        // 2-segment compression cases
        if n == 2 {
            let s2 = segs[1]
            if s2.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil {
                // e.g. "Z.02" should stay level 2
                return 2
            }
            if s2.range(of: #"^[A-Z]+[0-9]+$"#, options: .regularExpression) != nil {
                // e.g. "I.A010" should be level 4
                return 4
            }
            return implied // normal 2-seg: 3
        }

        // 3+ segments: single digit suffix ⇒ stay 4; multi-digit ⇒ 5
        if n >= 3 {
            let s3 = segs[2]
            // ignore pure digits (e.g. "010") → remain 4
            if s3.range(of: #"^[0-9]+$"#, options: .regularExpression) == nil,
               s3.range(of: #"^[A-Z]+"#, options: .regularExpression) != nil,
               let r = s3.range(of: #"[0-9]+$"#, options: .regularExpression) {
                let digitsCount = s3[r].count
                if digitsCount > 1 { implied = 5 } // multi-digit bump
            }
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
