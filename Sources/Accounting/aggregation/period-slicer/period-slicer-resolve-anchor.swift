import Foundation

public extension PeriodSlicer {
    static func anchor(
        shape: PeriodShape,
        anchor rawAnchor: String?,
        defaultAnchor: @autoclosure () -> Date = Date(),
        timeZone: TimeZone = .current
    ) throws -> ResolvedPeriodAnchorRequest {
        let resolvedAnchor: Date

        if let rawAnchor,
           !rawAnchor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedAnchor = try PeriodAnchorParser.parse(
                rawAnchor,
                kind: shape.kind,
                timeZone: timeZone
            )
        } else {
            resolvedAnchor = defaultAnchor()
        }

        return .init(
            shape: shape,
            anchor: resolvedAnchor
        )
    }
}
