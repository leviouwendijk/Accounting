import Foundation

public struct CapitalRoots: Sendable, Codable {
    public let profitShareCode: String
    public let contributionRootCode: String
    public let drawingRootCode: String
    public let equityTotalFallbackCode: String?

    public init(
        profitShareCode: String,
        contributionRootCode: String,
        drawingRootCode: String,
        equityTotalFallbackCode: String? = nil
    ) {
        self.profitShareCode = profitShareCode
        self.contributionRootCode = contributionRootCode
        self.drawingRootCode = drawingRootCode
        self.equityTotalFallbackCode = equityTotalFallbackCode
    }
}
