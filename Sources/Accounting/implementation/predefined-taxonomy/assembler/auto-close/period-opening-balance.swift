import Foundation

public struct PeriodOpeningRouting: Codable, Sendable {
    /// Equity subtree root (e.g. "BEiv")
    public let equityAnchorCode: String
    /// Equity opening leaf (e.g. "BEivKapOndBeg"). If missing, equity falls back to the anchor group.
    public let equityOpeningCode: String?
    /// Branch anchors that should **keep openings at the leaf** (no Beg routing), e.g. ["BLim"].
    public let exceptionKeepLeafAnchors: [String]

    public init(
        equityAnchorCode: String,
        equityOpeningCode: String?,
        exceptionKeepLeafAnchors: [String] = []
    ) {
        self.equityAnchorCode = equityAnchorCode
        self.equityOpeningCode = equityOpeningCode
        self.exceptionKeepLeafAnchors = exceptionKeepLeafAnchors
    }
}

