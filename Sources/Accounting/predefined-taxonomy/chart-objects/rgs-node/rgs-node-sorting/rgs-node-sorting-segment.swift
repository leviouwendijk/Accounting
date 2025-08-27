import Foundation

/// parsed view of a single Sorting segment, e.g. "A010" → alpha="A", number=10
public struct SortingSegment: Sendable, Hashable {
    public let raw: String
    public let alpha: String              // leading letters (may be empty)
    public let numberString: Substring?   // trailing digits as substring
    public let number: Int?               // parsed numeric tail (nil if none)

    @inlinable
    public init(raw: String) {
        self.raw = raw

        // Split into leading letters and trailing digits (if any).
        // Matches: "", "A", "AB", "010", "A010", "Z.02" (after splitting on '.')
        let scalars = raw.unicodeScalars
        var splitIdx = scalars.startIndex
        while splitIdx < scalars.endIndex, CharacterSet.uppercaseLetters.contains(scalars[splitIdx]) {
            splitIdx = scalars.index(after: splitIdx)
        }

        let alphaPart = String(String.UnicodeScalarView(scalars[scalars.startIndex..<splitIdx]))
        let tail = String.UnicodeScalarView(scalars[splitIdx..<scalars.endIndex])
        let tailStr = String(tail)

        // Tail must be all digits to count as a numeric suffix.
        if !tailStr.isEmpty, tailStr.unicodeScalars.allSatisfy({ CharacterSet.decimalDigits.contains($0) }) {
            self.alpha = alphaPart
            self.numberString = Substring(tailStr)
            self.number = Int(tailStr) // leading zeros handled naturally ("010" → 10)
        } else {
            self.alpha = alphaPart
            self.numberString = nil
            self.number = nil
        }
    }
}
