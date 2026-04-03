import Foundation

extension PeriodSlicer {
    public static func resolve(
        shape requestedShape: PeriodShape,
        anchor rawAnchor: String?,
        customFrom rawCustomFrom: String?,
        customTo rawCustomTo: String?,
        defaultAnchor: @autoclosure () -> Date = Date(),
        timeZone: TimeZone = .current
    ) throws -> ResolvedPeriodRequest {
        let calendar = periodCalendar(
            timeZone: timeZone
        )

        let trimmedAnchor = normalizedPeriodInput(rawAnchor)
        let trimmedCustomFrom = normalizedPeriodInput(rawCustomFrom)
        let trimmedCustomTo = normalizedPeriodInput(rawCustomTo)

        let parsedCustomFrom = try trimmedCustomFrom.map {
            try PeriodAnchorParser.parseFullDate(
                $0,
                label: "--from",
                timeZone: timeZone,
                calendar: calendar
            )
        }

        let parsedCustomTo = try trimmedCustomTo.map {
            try PeriodAnchorParser.parseFullDate(
                $0,
                label: "--to",
                timeZone: timeZone,
                calendar: calendar
            )
        }

        if let parsedCustomFrom,
           let parsedCustomTo,
           parsedCustomFrom > parsedCustomTo {
            throw PeriodAnchorParseError.invalidCustomRange(
                from: parsedCustomFrom,
                to: parsedCustomTo
            )
        }

        let effectiveShape: PeriodShape = {
            guard parsedCustomFrom != nil || parsedCustomTo != nil else {
                return requestedShape
            }

            return .init(
                kind: .custom,
                rangeToDate: false
            )
        }()

        let resolvedAnchor: Date = try {
            if let trimmedAnchor {
                return try PeriodAnchorParser.parse(
                    trimmedAnchor,
                    kind: requestedShape.kind,
                    timeZone: timeZone,
                    calendar: calendar
                )
            }

            if let parsedCustomFrom {
                return parsedCustomFrom
            }

            if let parsedCustomTo {
                return parsedCustomTo
            }

            return defaultAnchor()
        }()

        let windows = Self.resolve(
            shape: effectiveShape,
            anchor: resolvedAnchor,
            customFrom: parsedCustomFrom,
            customTo: parsedCustomTo,
            calendar: calendar
        )

        return .init(
            requestedShape: requestedShape,
            effectiveShape: effectiveShape,
            anchor: resolvedAnchor,
            customFrom: parsedCustomFrom,
            customTo: parsedCustomTo,
            windows: windows
        )
    }

    @inline(__always)
    private static func normalizedPeriodInput(
        _ raw: String?
    ) -> String? {
        guard let raw else {
            return nil
        }

        let trimmed = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty
            ? nil
            : trimmed
    }
}
