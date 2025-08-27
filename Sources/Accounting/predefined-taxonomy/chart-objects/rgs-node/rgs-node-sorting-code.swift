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

    /// Excel mapping:
    /// - Take at most the first 3 dot-segments for hierarchy depth.
    /// - implied = hierDepth + 1
    /// - If hierDepth == 3 and the 3rd segment is LETTERS followed by >=2 digits, bump to 5.
    ///   Examples: A10, AA10, A010 → bump; A1 → no bump; 010 (digits only) → no bump.
    /// - A 4th, digits-only segment (e.g. ".020") is ignored for level purposes.
    @inlinable
    public var xlsxImpliedLevel: Int {
        let segs = segments
        let hierDepth = min(segs.count, 3)
        var implied = hierDepth + 1

        if hierDepth == 3 {
            let third = segs[2]
            // letters + 2+ digits (no bump for digits-only like "010", or letters+1 digit like "A1")
            if third.range(of: #"^[A-Z]+[0-9]{2,}$"#, options: .regularExpression) != nil {
                implied = 5
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
