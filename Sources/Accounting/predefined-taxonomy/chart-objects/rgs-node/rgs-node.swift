import Foundation

public struct RGSNode: Sendable, Codable {
    public let id: Int
    public let codes: RGSNodeCodes
    public let links: RGSNodeLinks
    public let sorting: RGSNodeSortingCode
    public let reference: String
    public let labels: RGSNodeLabels
    public let direction: Direction
    public let level: UInt8
    public let filters: RGSNodeFilters?

    public let side: RGSNodeSide      // codes.code.hasPrefix("B")
    public let sortingKey: String          // e.g. sorting.key
    public let omslagId: Int?             // pre-resolve to codes.id
    public let directionSign: Int8

    public init(
        id: Int,
        codes: RGSNodeCodes,
        links: RGSNodeLinks,
        sorting: RGSNodeSortingCode,
        reference: String,
        labels: RGSNodeLabels,
        direction: Direction,
        level: UInt8,
        filters: RGSNodeFilters?,

        side: RGSNodeSide,
        sortingKey: String,
        omslagId: Int?,
        directionSign: Int8? = nil,
    ) throws {
        // 1) sortingKey sanity
        let expectedKey = sorting.key
        guard expectedKey == sortingKey else {
            throw RGSNodeInvariantError.sortingKeyMismatch(expected: expectedKey, got: sortingKey, code: codes.code)
        }

        // 2) level vs segments
        let segs = sorting.segments.count
        guard Int(level) == segs else {
            throw RGSNodeInvariantError.levelMismatch(level: level, segments: segs, code: codes.code)
        }

        // 3) side matches identifier prefix
        let prefix = codes.code.first.map(String.init) ?? ""
        let expSide: RGSNodeSide = (prefix == "B") ? .balance : .profitLoss
        guard side == expSide else {
            throw RGSNodeInvariantError.sideMismatch(expected: expSide, gotPrefix: prefix, code: codes.code)
        }

        // 4) parentKey & l2Key presence
        if level > 1 {
            guard links.parentKey != nil else {
                throw RGSNodeInvariantError.missingParentKey(level: level, code: codes.code)
            }
        }
        guard !links.l2Key.isEmpty else {
            throw RGSNodeInvariantError.emptyL2Key(code: codes.code)
        }

        // 5) directionSign validity (if provided)
        let sign = directionSign ?? direction.int
        guard sign == 1 || sign == -1 else {
            throw RGSNodeInvariantError.invalidDirectionSign(sign: sign, code: codes.code)
        }

        // // 6) omslag resolution (if any)
        // if let omslagIdent = codes.omslag {
        //     guard let resolved = index.byIdentifier[omslagIdent] else {
        //         throw RGSNodeInvariantError.unresolvedOmslagIdentifier(omslag: omslagIdent, code: codes.code)
        //     }
        //     if let provided = omslagId, provided != resolved {
        //         throw RGSNodeInvariantError.omslagIdMismatch(omslag: omslagIdent, resolvedId: resolved, providedId: provided, code: codes.code)
        //     }
        // }
        // save for RGSBuilder or somewhere later

        self.id = id
        self.codes = codes
        self.links = links
        self.sorting = sorting
        self.reference = reference
        self.labels = labels
        self.direction = direction
        self.level = level
        self.filters = filters

        self.side = side
        self.sortingKey = sortingKey
        self.omslagId = omslagId
        self.directionSign = directionSign ?? direction.int
    }
}
