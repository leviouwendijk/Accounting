import Foundation

public enum PeriodSlicer {}

@inline(__always)
public func absDate(_ d: DateSpecification) -> Date? {
    if case let .absolute(x) = d { return x }
    return nil
}

@inline(__always)
public func filterEntries(_ src: [ResolvedEntry], within w: PeriodWindow) -> [ResolvedEntry] {
    src.filter { re in
        guard let d = absDate(re.date) else { return false }
        return within(d, window: w)
    }
}

@inline(__always)
public func within(_ date: Date, window w: PeriodWindow) -> Bool {
    if let f = w.from, date < f { return false }
    if let t = w.to,   date > t { return false }
    return true
}
