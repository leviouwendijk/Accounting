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
        // L1: empty or side-only
        if segs == 0 { return 1 }
        if segs == 1, let s0 = segments.first, (s0 == "B" || s0 == "W") { return 1 }

        var implied = segs + 1
        if segs >= 3 {
            let last = segments.last ?? ""
            // match letters + exactly 3 digits at the end, e.g. "A010"
            if last.range(of: #"^[A-Z]+[0-9]{3}$"#, options: .regularExpression) != nil {
                implied += 1
            }
        }
        return implied
    }
}
