import Accounting
import Foundation

extension EntryCompilerSlugs {
    static func assetsOverview(
        kind: PeriodKind,
        toDate: Bool,
        window: PeriodWindow,
        timeZone: TimeZone
    ) -> String {
        [
            "assets-overview",
            kind.rawValue,
            toDate ? "to-date" : nil,
            window.filenameSlug(
                timeZone: timeZone
            ),
        ]
        .compactMap { $0 }
        .joined(separator: "-")
    }

    static func assetsShares(
        kind: PeriodKind,
        history: Bool,
        window: PeriodWindow,
        timeZone: TimeZone
    ) -> String {
        [
            "assets-shares",
            kind.rawValue,
            history ? "history" : nil,
            window.filenameSlug(
                timeZone: timeZone
            ),
        ]
        .compactMap { $0 }
        .joined(separator: "-")
    }
}
