import Foundation

public func earliestPostingDate<Seq: Sequence>(
    in entries: Seq,
    using settings: EntryCompilerSettings
) -> Date? where Seq.Element == Entry {
    return entries.lazy
        .compactMap { $0.resolvedPostingDate(using: settings) }
        .min()
}

public func earliestAbsoluteDate(
    entries: [Entry],
    settings: EntryCompilerSettings
) throws -> Date {
    var minDate: Date?
    for e in entries {
        let spec = try e.date.resolved(for: e, using: settings) // returns .absolute
        if case .absolute(let d) = spec {
            if let cur = minDate {
                if d < cur { minDate = d }
            } else {
                minDate = d
            }
        }
    }
    return minDate ?? Date.distantPast
}
