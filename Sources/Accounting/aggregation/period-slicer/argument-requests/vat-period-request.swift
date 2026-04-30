import Arguments
import Foundation
import Methods
import Primitives

public struct VATPeriodRequest: Sendable {
    public var kind: PeriodKind
    public var toDate: Bool
    public var anchor: String?
    public var from: String?
    public var to: String?
    public var quarter: VATQuarterAnchor?

    public var shape: PeriodShape {
        PeriodShape(
            kind: kind,
            rangeToDate: toDate
        )
    }

    public init(
        kind: PeriodKind = .year,
        toDate: Bool = false,
        anchor: String? = nil,
        from: String? = nil,
        to: String? = nil,
        quarter: VATQuarterAnchor? = nil
    ) throws {
        let anchor = trimmedOrNil(
            anchor
        )

        let from = trimmedOrNil(
            from
        )

        let to = trimmedOrNil(
            to
        )

        if let quarter {
            guard kind == .quarter else {
                throw ArgumentValidationError(
                    "--quarter can only be used with the quarter period kind."
                )
            }

            guard anchor == nil else {
                throw ArgumentValidationError(
                    "Use either --quarter or --anchor, not both."
                )
            }

            guard from == nil,
                  to == nil else {
                throw ArgumentValidationError(
                    "--quarter cannot be combined with --from/--to."
                )
            }

            self.kind = .quarter
            self.anchor = quarter.rawValue
            self.quarter = quarter
        } else {
            self.kind = from != nil || to != nil
                ? .custom
                : kind
            self.anchor = anchor
            self.quarter = nil
        }

        self.toDate = toDate
        self.from = from
        self.to = to
    }

    public init(
        arguments: Options
    ) throws {
        try self.init(
            kind: arguments.kind,
            toDate: arguments.toDate,
            anchor: arguments.anchor,
            from: arguments.from,
            to: arguments.to,
            quarter: arguments.quarter
        )
    }

    public init(
        arguments: QuarterOptions
    ) throws {
        try self.init(
            kind: arguments.kind,
            toDate: arguments.toDate,
            anchor: arguments.anchor,
            from: arguments.from,
            to: arguments.to,
            quarter: arguments.quarter
        )
    }

    public struct Options: ArgumentGroup {
        @Arg(
            "period",
            default: .year
        )
        public var kind: PeriodKind

        @Flag("to-date")
        public var toDate: Bool

        @Opt("anchor")
        public var anchor: String?

        @Opt("from")
        public var from: String?

        @Opt("to")
        public var to: String?

        @Opt("quarter")
        public var quarter: VATQuarterAnchor?

        public init() {}
    }

    public struct QuarterOptions: ArgumentGroup {
        @Arg(
            "period",
            default: .quarter
        )
        public var kind: PeriodKind

        @Flag("to-date")
        public var toDate: Bool

        @Opt("anchor")
        public var anchor: String?

        @Opt("from")
        public var from: String?

        @Opt("to")
        public var to: String?

        @Opt("quarter")
        public var quarter: VATQuarterAnchor?

        public init() {}
    }
}

public struct VATQuarterAnchor: Sendable, Equatable, Hashable, ArgumentValue {
    public var value: YearQuarter

    public init(
        _ rawValue: String
    ) throws {
        guard let trimmed = trimmedOrNil(
            rawValue
        ) else {
            throw ArgumentValidationError(
                "--quarter cannot be blank."
            )
        }

        do {
            self.value = try YearQuarter(
                label: trimmed
            )
        } catch {
            throw ArgumentValidationError(
                "Invalid --quarter value: \(trimmed). Expected format like 2025Q4."
            )
        }
    }

    public var rawValue: String {
        value.label
    }

    public static var parser: AnyArgumentValueParser<VATQuarterAnchor> {
        .init { rawValue in
            try VATQuarterAnchor(
                rawValue
            )
        }
    }

    public static var valueName: String {
        "quarter"
    }

    public static func raw(
        _ value: VATQuarterAnchor
    ) -> String {
        value.rawValue
    }
}
