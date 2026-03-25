import Foundation

public struct RGSNodeSortingCode: Sendable, Codable, Hashable, SortingKeyProviding, Comparable {
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

    // extended custom protocol
    @inlinable 
    public var sorteringSegments: [String] { 
        segments 
    }

    // comparable
    @inlinable 
    public static func < (lhs: Self, rhs: Self) -> Bool {
        sorteringLessThan(lhs, rhs)
    }
}

// not yet implemented for now
// designed to replace canonicalKey func in the RGSIndex.build(:)
//
// public extension RGSNodeSortingCode {
//     /// Merge trailing ".<LETTERS>.<DIGITS>" into ".<LETTERS><DIGITS>" once.
//     /// E.g. "E.H.A.020" -> "E.H.A020"
//     @inlinable
//     var canonicalized: RGSNodeSortingCode {
//         var segs = self.segments
//         guard segs.count >= 4 else { return self }               // need at least 4 to merge last two
//         let pen = segs[segs.count - 2]
//         let last = segs[segs.count - 1]
//         let isLetters = pen.range(of: #"^[A-Z]+$"#, options: .regularExpression) != nil
//         let isDigits  = last.range(of: #"^[0-9]+$"#, options: .regularExpression) != nil
//         if isLetters && isDigits {
//             segs[segs.count - 2] = pen + last
//             segs.removeLast()
//             return RGSNodeSortingCode(segments: segs)
//         }
//         return self
//     }

//     @inlinable
//     var canonicalKey: String { canonicalized.key }

//     @inlinable
//     var canonicalParentKey: String? { canonicalized.parentKeyString }
// }
