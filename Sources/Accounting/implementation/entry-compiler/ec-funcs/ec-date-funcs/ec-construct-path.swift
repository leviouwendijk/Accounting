// for: exporting legacy entries by project path policy
import Foundation
import plate

public struct YQM: Hashable, Sendable {
    public let year: Int
    public let quarter: Int    // 1...4
    public let month: Int      // 1...12
    
    public init(
        year: Int,
        quarter: Int,    // 1...4,
        month: Int      // 1...12
    ) {
        self.year = year
        self.quarter = quarter
        self.month = month
    }
}

@inlinable
public func yqm(for date: Date, tz: TimeZone = .current) throws -> YQM {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = tz
    let comps = cal.dateComponents([.year, .month], from: date)
    let y = comps.year!
    let m = comps.month!
    let q = Int(try m.yearlyQuarter().rawValue)
    return .init(year: y, quarter: q, month: m)
}

public struct EntryPathOptions: Sendable {
    public var padMonth: Bool = false   // e.g. 03 instead of 3

    public init(padMonth: Bool = false) {
        self.padMonth = padMonth 
    }
}

/// Build `<root>/<year>/<quarter>/<month>/<filename>.ec`
@inlinable
public func makeEntryPath(
    root: URL,
    yqm: YQM,
    filename: String,
    options: EntryPathOptions = .init()
) -> URL {
    let monthDir = options.padMonth ? String(format: "%02d", yqm.month) : String(yqm.month)
    return root
    .appendingPathComponent(String(yqm.year), isDirectory: true)
    .appendingPathComponent(String(yqm.quarter), isDirectory: true)
    .appendingPathComponent(monthDir, isDirectory: true)
    .appendingPathComponent(filename).appendingPathExtension("ec")
}
