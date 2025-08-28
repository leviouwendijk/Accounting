import Foundation
import plate

public struct RGSNode: Sendable, Codable, JSONWritable {
    // COMMON
    public let id: Int
    public let codes: RGSNodeCodes
    public let omslagId: Int?

    public let labels: RGSNodeLabels
    public let direction: Direction?          // natural DR/CR if known
    public let level: UInt8
    public let temporality: Temporality       // .instant / .duration cache

    public let side: RGSNodeSide              // inferred from codes.code prefix (B*/W*)
    public let directionSign: Int8?           // ±1 for postables, otherwise nil

    // SOURCE BUNDLES
    public let xlsx: RGSNodeXLSXConcept?      // nil for XBRL-built nodes
    public let xbrl: RGSNodeXBRLConcept?      // nil for XLSX-built nodes

    // Postable: XBRL is authoritative; XLSX fallback = has a direction
    public var postable: Bool {
        if let xb = xbrl { return xb.postable }
        return direction != nil
    }

    public init(
        id: Int,
        codes: RGSNodeCodes,

        labels: RGSNodeLabels,
        direction: Direction? = nil,
        level: UInt8,
        temporality: Temporality,

        side: RGSNodeSide,
        omslagId: Int? = nil,
        directionSign: Int8? = nil,

        xlsx: RGSNodeXLSXConcept? = nil,
        xbrl: RGSNodeXBRLConcept? = nil
    ) throws {
        self.id = id
        self.codes = codes

        self.labels = labels
        self.direction = direction
        self.level = level
        self.temporality = temporality

        self.side = side
        self.omslagId = omslagId

        // Auto-derive sign from direction if not provided
        if let d = direction {
            self.directionSign = directionSign ?? d.int
        } else {
            self.directionSign = directionSign  // may be nil for headers/non-postables
        }

        self.xlsx = xlsx
        self.xbrl = xbrl

        // -------- Invariants --------

        // (A) Side must match code prefix (always)
        let expSide: RGSNodeSide = (codes.code.first == "B") ? .balance : .profitLoss
        guard side == expSide else {
            throw RGSNodeInvariantError.sideMismatch(
                expected: expSide,
                gotPrefix: String(codes.code.prefix(1)),
                code: codes.code
            )
        }

        // (B) Excel-only invariants
        if let xl = xlsx {
            // 1) sortingKey sanity (unchanged)
            guard xl.sorting.key == xl.cachedSortingKey else {
                throw RGSNodeInvariantError.sortingKeyMismatch(
                    expected: xl.sorting.key,
                    got: xl.cachedSortingKey,
                    code: codes.code
                )
            }

            // guard xl.sorting.isConsistent(withExcelLevel: level) else {
            //     throw RGSNodeInvariantError.levelMismatch(
            //         level: level,
            //         segments: xl.sorting.segments,
            //         code: codes.code
            //     )
            // }
            let implied = xl.sorting.xlsxImpliedLevel
            if let report = xl.sorting.softConsistencyReport(
                expectedLevel: level,
                code: codes.code,
                implied: implied
            ) {
                print(report)
            }

            // 3) parentKey & l2Key presence (keep these)
            let segsCount = xl.sorting.segments.count
            if level > 1 && segsCount > 1 {
                guard xl.links.parentKey != nil else {
                    throw RGSNodeInvariantError.missingParentKey(level: level, code: codes.code)
                }
            }
            guard !xl.links.l2Key.isEmpty else {
                throw RGSNodeInvariantError.emptyL2Key(code: codes.code)
            }
        }

        // (C) XBRL-only invariants (only for postable concepts)
        if let xb = xbrl, xb.postable {
            guard direction != nil else {
                throw RGSNodeInvariantError.missingDirectionForPostable(code: codes.code)
            }
            guard let s = directionSign, (s == 1 || s == -1) else {
                throw RGSNodeInvariantError.invalidDirectionSign(sign: directionSign, code: codes.code)
            }
        }

        // (D) Optional consistency: if both are present, they must agree
        if let d = direction, let s = directionSign {
            precondition(s == d.int, "directionSign mismatch for \(codes.code)")
        }
    }

    public func with(omslagId newValue: Int?) throws -> RGSNode {
        try RGSNode(
            id: id, codes: codes,
            labels: labels, direction: direction,
            level: level, temporality: temporality,
            side: side, omslagId: newValue,
            directionSign: directionSign,
            xlsx: xlsx, xbrl: xbrl
        )
    }

    /// Return a new RGSNode with the provided xlsx concept replaced.
    /// This mirrors your existing `with(omslagId:)` pattern.
    public func with(xlsx newXLSX: RGSNodeXLSXConcept?) throws -> RGSNode {
        try RGSNode(
            id: self.id,
            codes: self.codes,
            labels: self.labels,
            direction: self.direction,
            level: self.level,
            temporality: self.temporality,
            side: self.side,
            omslagId: self.omslagId,
            directionSign: self.directionSign,
            xlsx: newXLSX,
            xbrl: self.xbrl
        )
    }
}

extension Array: @retroactive JSONWritable where Element == RGSNode {}
