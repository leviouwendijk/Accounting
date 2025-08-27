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
}
