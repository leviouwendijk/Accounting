import Foundation

public enum RGSAssembler {}

extension RGSAssembler {
    @inline(__always)
    public static func makeForcedSets(
        index: RGSIndex,
        cut: AssembleCut,
        parentById: [Int: Int]
    ) -> (forcedIds: Set<Int>, forcedChain: Set<Int>) {
        let forcedIds = Set(cut.includeCodes.compactMap { index.byIdentifier[$0] })
        let forcedChain: Set<Int> = cut.includeIntermediates ? Set(forcedIds.flatMap { chainToRoot($0, parentById: parentById) }) : forcedIds
        return (forcedIds, forcedChain)
    }
}
