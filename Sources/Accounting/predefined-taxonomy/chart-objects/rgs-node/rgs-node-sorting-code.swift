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

    /// Excel quirk: levels 4–5 keep only three dot-segments and put detail inside the last token (e.g. `A010`).
    /// - Returns: `true` iff the sorting code shape is consistent with the provided RGS level.
    @inlinable
    public func isConsistent(withExcelLevel level: UInt8) -> Bool {
        let segs = segments.count
        if level <= 3 {
            return segs == Int(level)
        } else {
            return segs >= 3
        }
    }
}
