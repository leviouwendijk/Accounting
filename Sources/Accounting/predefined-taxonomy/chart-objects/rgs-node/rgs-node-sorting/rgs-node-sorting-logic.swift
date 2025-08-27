import Foundation

/// Compare two Sorting segments:
/// 1) Compare alpha lexically (case-sensitive, but your data is A–Z).
/// 2) If alpha equal and both have numeric tails → compare numbers (10 > 2).
/// 3) If only one has numeric tail → the one *without* tail sorts first (headers before numbered).
/// 4) If both lack numeric tails → compare raw lexically as a final tie-breaker.
@inlinable
public func compareSortingSegments(_ lhs: SortingSegment, _ rhs: SortingSegment) -> ComparisonResult {
    if lhs.alpha != rhs.alpha {
        return lhs.alpha < rhs.alpha ? .orderedAscending : .orderedDescending
    }

    switch (lhs.number, rhs.number) {
    case let (l?, r?):
        if l == r { return .orderedSame }
        return l < r ? .orderedAscending : .orderedDescending
    case (nil, nil):
        // No numeric tails; fall back to raw lexical to keep stable ordering within same alpha.
        if lhs.raw == rhs.raw { return .orderedSame }
        return lhs.raw < rhs.raw ? .orderedAscending : .orderedDescending
    case (nil, _?):
        // Header (no number) comes before numbered sub-lines within same alpha group.
        return .orderedAscending
    case (_?, nil):
        return .orderedDescending
    }
}

/// Compare two Sorting paths (already split on ".") using the rules:
/// - Compare segment-by-segment with `compareSortingSegments`.
/// - If all compared segments are equal but one path is a strict prefix of the other,
///   the **shorter** path sorts first (header before its children).
@inlinable
public func compareSortingPaths(_ left: [String], _ right: [String]) -> ComparisonResult {
    let n = min(left.count, right.count)
    for i in 0..<n {
        let lSeg = SortingSegment(raw: left[i])
        let rSeg = SortingSegment(raw: right[i])
        let c = compareSortingSegments(lSeg, rSeg)
        if c != .orderedSame { return c }
    }
    if left.count == right.count { return .orderedSame }
    return left.count < right.count ? .orderedAscending : .orderedDescending
}

@inlinable
public func sorteringLessThan<T: SortingKeyProviding>(_ a: T, _ b: T) -> Bool {
    makeSortingLessThan()(a.sorteringSegments, b.sorteringSegments)
}
