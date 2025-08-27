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
        let hasDigits = segments.contains { $0.rangeOfCharacter(from: .decimalDigits) != nil }
        var implied = segs + 1
        if segs >= 3 && hasDigits {
            implied += 1
        }
        return implied
    }
}
