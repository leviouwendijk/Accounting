import Arguments
import Foundation
import Methods

public struct EntryCompilerPeriodRequest: Sendable {
    public var kind: PeriodKind
    public var toDate: Bool
    public var anchor: String?
    public var from: String?
    public var to: String?

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
        to: String? = nil
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

        self.kind = from != nil || to != nil
            ? .custom
            : kind

        self.toDate = toDate
        self.anchor = anchor
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
            to: arguments.to
        )
    }

    public init(
        arguments: MonthOptions
    ) throws {
        try self.init(
            kind: arguments.kind,
            toDate: arguments.toDate,
            anchor: arguments.anchor,
            from: arguments.from,
            to: arguments.to
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

        public init() {}
    }

    public struct MonthOptions: ArgumentGroup {
        @Arg(
            "period",
            default: .month
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

        public init() {}
    }
}
