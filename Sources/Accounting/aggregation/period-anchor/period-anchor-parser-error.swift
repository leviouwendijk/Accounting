import Foundation

public enum PeriodAnchorParseError: LocalizedError, Sendable {
    case invalidAnchor(
        raw: String,
        kind: PeriodKind,
        expected: String
    )
    case invalidFullDate(
        raw: String,
        label: String
    )
    case invalidCustomRange(
        from: Date,
        to: Date
    )

    public var errorDescription: String? {
        switch self {
        case .invalidAnchor(let raw, let kind, let expected):
            return "Invalid anchor '\(raw)' for period kind '\(kind.rawValue)'. Expected \(expected)."

        case .invalidFullDate(let raw, let label):
            return "Invalid \(label) value '\(raw)'. Use YYYY-MM-DD."

        case .invalidCustomRange(let from, let to):
            return "Invalid custom range: --from (\(from)) must be earlier than or equal to --to (\(to))."
        }
    }
}
