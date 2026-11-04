import AccountingV2
import AccountingV2Fixtures
import Foundation

extension V2CommandRunner {
    static func runComparative() throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        func date(_ value: String) throws -> Date {
            guard let result = formatter.date(from: value) else {
                throw Error.invalidDate(value)
            }
            return result
        }

        let fixture = try V2ClosingFixture()
        let ledger = try fixture.sampleLedger()
        let selection = try MovementSelection(.init(source: .explicit([
            .init(role: .previous,
                  start: date("2025-01-01"),
                  end: date("2026-01-01")),
            .init(role: .current,
                  start: date("2026-01-01"),
                  end: date("2027-01-01"))
        ])))
        let slices = try ComparativeSlices(.init(
            ledger: ledger,
            selection: selection
        ))

        print("ec_v2 comparative | fixture=closing | recorded-only")
        print("previous=[2025-01-01, 2026-01-01) current=[2026-01-01, 2027-01-01)")
        print("historical_before_previous=\(slices.historical_before_previous.postings.count)")
        print("previous_movements=\(slices.previous.movements.postings.count)")
        print("historical_before_current=\(slices.historical_before_current.postings.count)")
        print("current_movements=\(slices.current.movements.postings.count)")
        print("current_cumulative=\(slices.current.recorded_position.postings.count)")

        for account in fixture.accountOrder {
            guard let previous = slices.previous.movements.amount(for: account),
                  let opening = slices.current.recorded_opening.amount(for: account),
                  let movements = slices.current.movements.amount(for: account),
                  let cumulative = slices.current.recorded_position.amount(for: account)
            else {
                continue
            }
            print("\(account.code) | previous=\(previous.posted) current_opening=\(opening.posted) current_movements=\(movements.posted) current_recorded=\(cumulative.posted)")
        }
        print("note=historical and previous overlap as views; no automatic closing or owner allocation")
    }
}
