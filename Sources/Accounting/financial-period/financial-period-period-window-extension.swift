import Foundation

public extension PeriodWindow {
    var isFinite: Bool {
        from != nil && to != nil
    }

    func inclusiveDayCount(
        calendar: Calendar = periodCalendar()
    ) -> Int? {
        guard let from, let to else {
            return nil
        }

        let start = calendar.startOfDay(for: from)
        let end = calendar.startOfDay(for: to)

        guard end >= start else {
            return nil
        }

        let delta = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        ).day ?? 0

        return delta + 1
    }
}
