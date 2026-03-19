import Foundation

/// A convenience: make a Comparator closure you can pass straight into `sorted(by:)`.
@inlinable
public func makeSortingLessThan() -> (_ a: [String], _ b: [String]) -> Bool {
    return { a, b in compareSortingPaths(a, b) == .orderedAscending }
}

/// Sort any collection of types that expose `SortingKeyProviding`.
@inlinable
public func sortedBySorting<T: SortingKeyProviding, C: Collection>(
    _ items: C
) -> [T] where C.Element == T {
    items.sorted(by: sorteringLessThan)
}

/// Sort plain string keys directly (e.g., ["A", "A.B", "A.B.A010", ...]).
@inlinable
public func sortedSortingKeys(_ keys: [String]) -> [String] {
    let split = keys.map { $0.split(separator: ".").map(String.init) }
    // Keep original alongside split to rejoin in original form.
    let zipped = zip(keys, split)
    let sortedPairs = zipped.sorted { a, b in
        compareSortingPaths(a.1, b.1) == .orderedAscending
    }
    return sortedPairs.map { $0.0 }
}
