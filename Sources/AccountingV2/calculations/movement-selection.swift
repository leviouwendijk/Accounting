import Foundation
import Primitives

/// Validated date windows for comparative movement reporting.
/// The selection does not imply fiscal closing or account carryforward.
public struct MovementSelection: Invariant, Sendable {
    public enum Unit: Sendable {
        case day
        case week
        case month
        case quarter
        case year

        fileprivate var component: Calendar.Component {
            switch self {
            case .day: .day
            case .week: .weekOfYear
            case .month: .month
            case .quarter: .quarter
            case .year: .year
            }
        }

        fileprivate var previousStep: (component: Calendar.Component, value: Int) {
            switch self {
            case .day: (.day, -1)
            case .week: (.weekOfYear, -1)
            case .month: (.month, -1)
            case .quarter: (.month, -3)
            case .year: (.year, -1)
            }
        }
    }

    public enum Role: Hashable, Sendable {
        case previous
        case current
        case offset(Int)
        case named(String)
    }

    public struct Window: Sendable {
        public let role: Role
        public let start: Date
        public let end: Date

        public init(role: Role, start: Date, end: Date) {
            self.role = role
            self.start = start
            self.end = end
        }
    }

    public struct Raw: Sendable {
        public enum Source: Sendable {
            case calendar(anchor: Date, unit: Unit, count: Int, calendar: Calendar)
            case explicit([Window])
        }

        public let source: Source

        public init(source: Source) {
            self.source = source
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case invalidAnchor
        case invalidCount(Int)
        case unresolvableWindow(Int)
        case emptySelection
        case invalidStart(Int)
        case invalidEnd(Int)
        case invalidRange(Int)
        case invalidRoleName
        case duplicateRole(Role)
        case unorderedWindows
        case overlappingWindows
    }

    public let windows: [Window]

    public init(
        anchor: Date,
        unit: Unit,
        count: Int = 2,
        calendar: Calendar = .current
    ) throws(Error) {
        try self.init(.init(source: .calendar(
            anchor: anchor,
            unit: unit,
            count: count,
            calendar: calendar
        )))
    }

    public init(_ raw: Raw) throws(Error) {
        let resolved: [Window]

        switch raw.source {
        case .explicit(let windows):
            resolved = windows

        case .calendar(let anchor, let unit, let count, let calendar):
            guard anchor.timeIntervalSinceReferenceDate.isFinite else {
                throw .invalidAnchor
            }
            guard count > 0 else {
                throw .invalidCount(count)
            }
            guard var interval = calendar.dateInterval(
                of: unit.component,
                for: anchor
            ) else {
                throw .unresolvableWindow(0)
            }

            var descending: [Window] = []
            descending.reserveCapacity(count)

            for index in 0..<count {
                let role: Role
                switch index {
                case 0: role = .current
                case 1: role = .previous
                default: role = .offset(-index)
                }

                descending.append(Window(
                    role: role,
                    start: interval.start,
                    end: interval.end
                ))

                if index + 1 < count {
                    let step = unit.previousStep
                    guard let shifted = calendar.date(
                        byAdding: step.component,
                        value: step.value,
                        to: interval.start
                    ), let earlier = calendar.dateInterval(
                        of: unit.component,
                        for: shifted
                    ), earlier.end == interval.start else {
                        throw .unresolvableWindow(-(index + 1))
                    }
                    interval = earlier
                }
            }

            resolved = Array(descending.reversed())
        }

        guard !resolved.isEmpty else {
            throw .emptySelection
        }

        var seen: Set<Role> = []
        var previous: Window?

        for (index, window) in resolved.enumerated() {
            guard window.start.timeIntervalSinceReferenceDate.isFinite else {
                throw .invalidStart(index)
            }
            guard window.end.timeIntervalSinceReferenceDate.isFinite else {
                throw .invalidEnd(index)
            }
            guard window.start < window.end else {
                throw .invalidRange(index)
            }
            if case .named(let name) = window.role,
               name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw .invalidRoleName
            }
            guard seen.insert(window.role).inserted else {
                throw .duplicateRole(window.role)
            }
            if let previous {
                if window.start < previous.start {
                    throw .unorderedWindows
                }
                if window.start < previous.end {
                    throw .overlappingWindows
                }
            }
            previous = window
        }

        self.windows = resolved
    }

    public func window(for role: Role) -> Window? {
        windows.first { $0.role == role }
    }

    public var previous: Window? {
        window(for: .previous)
    }

    public var current: Window? {
        window(for: .current)
    }
}
