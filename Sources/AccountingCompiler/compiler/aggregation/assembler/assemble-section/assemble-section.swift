import Accounting
import Foundation

public enum RGSAssembleSection: Sendable {
    public enum Balance: String, Sendable, Codable, CaseIterable {
        case assets, equity, liabilities
    }
    public enum Income: String, Sendable, Codable, CaseIterable {
        case profitLoss // placeholder; extend later
    }
    public enum Cash: String, Sendable, Codable, CaseIterable {
        case operating, investing, financing // placeholder; extend later
    }
}

public extension RGSAssembler {
    /// Extract the first “letter” segment used for A/J/K/O classification.
    /// e.g. "B.A.A020" -> "A", "A010" -> "A". Falls back to first non-"B" segment.
    @inline(__always)
    static func firstLetterSegment(from sortKey: String) -> String? {
        if sortKey.isEmpty { return nil }
        let parts = sortKey.split(separator: ".", omittingEmptySubsequences: true)
        guard !parts.isEmpty else { return nil }
        if parts[0] == "B", parts.count >= 2 { return String(parts[1].prefix(1)) }
        return String(parts[0].prefix(1))
    }

    // (Optional) resolve section roots if you still want to read the rolled totals at A/J/K directly
    static func resolveSectionRoot(_ letter: String, maps: RGSAssemblerResult) throws -> (key: String, id: Int) {
        let candidates = ["B.\(letter)", letter]
        for k in candidates { if let id = maps.keyToId[k] { return (k, id) } }
        throw SectioningError.sectionRootNotFound(letter: letter)
    }
}
