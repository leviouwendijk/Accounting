import Foundation

public struct SourceSpan: CustomStringConvertible, Codable, Sendable, Hashable {
    public let start: SourceLocation
    public let end: SourceLocation

    public init(
        start: SourceLocation,
        end: SourceLocation
    ) {
        self.start = start
        self.end = end
    }

    public func contains(
        line: Int,
        column: Int
    ) -> Bool {
        if line < start.line || line > end.line {
            return false
        }

        if start.line == end.line {
            return line == start.line
                && column >= start.column
                && column <= end.column
        }

        if line == start.line {
            return column >= start.column
        }

        if line == end.line {
            return column <= end.column
        }

        return true
    }

    public var description: String {
        if start.file == end.file, start.line == end.line {
            return "\(start.line):\(start.column)-\(end.column)"
        }

        return "\(start)-\(end)"
    }
}
