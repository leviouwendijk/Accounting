import Foundation

public enum RGSNodeInvariantError: Error, LocalizedError, Sendable {
    case sortingKeyMismatch(expected: String, got: String, code: String)
    case levelMismatch(level: UInt8, segments: [String], code: String)
    case sideMismatch(expected: RGSNodeSide, gotPrefix: String, code: String)
    case missingParentKey(level: UInt8, code: String)
    case emptyL2Key(code: String)
    case unresolvedOmslagIdentifier(omslag: String, code: String)
    case omslagIdMismatch(omslag: String, resolvedId: Int, providedId: Int, code: String)
    case invalidDirectionSign(sign: Int8?, code: String)
    case missingDirectionForPostable(code: String)

    public var errorDescription: String? {
        switch self {
        case let .sortingKeyMismatch(exp, got, code):
            return "RGSNode invariant failed for \(code): sortingKey must mirror sorting.key (expected \(exp), got \(got))."
        case let .levelMismatch(level, segments, code):
            return "RGSNode invariant failed for \(code): level \(level) does not equal sorting.segments.count \(segments.count).\n    Segments: \(segments)."
        case let .sideMismatch(exp, prefix, code):
            return "RGSNode invariant failed for \(code): side \(exp) does not match code prefix '\(prefix)'."
        case let .missingParentKey(level, code):
            return "RGSNode invariant failed for \(code): parentKey must exist for level \(level) (> 1)."
        case let .emptyL2Key(code):
            return "RGSNode invariant failed for \(code): l2Key must not be empty."
        case let .unresolvedOmslagIdentifier(omslag, code):
            return "RGSNode invariant failed for \(code): omslag identifier '\(omslag)' not found in index."
        case let .omslagIdMismatch(omslag, resolvedId, providedId, code):
            return "RGSNode invariant failed for \(code): omslag '\(omslag)' resolved id \(resolvedId) ≠ provided \(providedId)."
        case let .invalidDirectionSign(sign, code):
            return "RGSNode invariant failed for \(code): direction sign must be 1 or -1, got \(sign ?? 0)."
        case let .missingDirectionForPostable(code):
            return "RGSNode invariant failed for \(code): postable RGSNode must be provided a balance direction."
        }
    }

    public var failureReason: String? {
        switch self {
        case .sortingKeyMismatch: return "Derived sortingKey must equal the joined segments from Sortering."
        case .levelMismatch:      return "RGS defines level as the number of Sortering path segments."
        case .sideMismatch:       return "‘B…’ codes are balance; ‘W…’ codes are profit/loss."
        case .missingParentKey:   return "Non-root nodes require a parent group key for roll-ups."
        case .emptyL2Key:         return "L2 group key is required for standard grouping."
        case .unresolvedOmslagIdentifier: return "All omslag targets must be resolvable in the compiled index."
        case .omslagIdMismatch:   return "If an omslagId is provided, it must match the identifier lookup."
        case .invalidDirectionSign: return "Hot-path sign cache must be +1 (debit) or −1 (credit)."
        case .missingDirectionForPostable: return "Balance directions are required for correct aggregation"
        }
    }
}

public enum RGSNodeResolutionError: Error, CustomStringConvertible {
    case unresolvedOmslag(references: [(code: String, omslag: String)])

    public var description: String {
        switch self {
        case .unresolvedOmslag(let refs):
            let lines = refs.map { "• code=\($0.code) → omslag=\($0.omslag)" }.joined(separator: "\n")
            return "Failed to resolve omslag identifiers:\n\(lines)"
        }
    }
}
