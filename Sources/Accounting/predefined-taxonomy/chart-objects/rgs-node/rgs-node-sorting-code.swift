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

    @inlinable
    public var xlsxImpliedLevel: Int {
        let segs = segments.count
        var implied = segs + 1
        if segs >= 3 {
            let last = segments.last ?? ""
            // bump only if last token is LETTERS followed by 2+ digits (e.g. A10, AA10, A010)
            if last.range(of: #"^[A-Z]+[0-9]{2,}$"#, options: .regularExpression) != nil {
                implied += 1
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
