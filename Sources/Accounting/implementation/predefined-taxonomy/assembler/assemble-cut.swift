import Foundation

public struct AssembleCut: Sendable {
    public var target: TargetLevel                // L2..L5
    public var includeCodes: [String] = []        // RGS identifiers to *force include*
    public var includeIntermediates: Bool = true  // also show parent chain for forced items
    public var omitZerosBeyondLevel1: Bool = true // drop amt==0 when level>1 (unless forced)

    public init(
        target: TargetLevel,
        includeCodes: [String] = [],
        includeIntermediates: Bool = true,
        omitZerosBeyondLevel1: Bool = true
    ) {
        self.target = target
        self.includeCodes = includeCodes
        self.includeIntermediates = includeIntermediates
        self.omitZerosBeyondLevel1 = omitZerosBeyondLevel1
    }
}
