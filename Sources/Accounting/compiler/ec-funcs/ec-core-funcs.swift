import Foundation

@inline(__always)
public func makeEncoder() -> JSONEncoder {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return enc
}

@inline(__always)
public func ensureDir(_ url: URL) throws {
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

@inline(__always)
public func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
    let data = try makeEncoder().encode(value)
    try data.write(to: url, options: .atomic)
}

public extension Decimal {
    var magnitude: Decimal { self < 0 ? -self : self }
}

@inlinable
public func isoDate(_ d: Date) -> String {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withFullDate]
    return f.string(from: d)
}

