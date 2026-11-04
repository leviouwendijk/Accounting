import AccountingV2
import AccountingV2Fixtures
import Foundation

extension V2CommandRunner {
    /// Synthetic demonstration only: an accepted 2025 closing plus the
    /// unclosed 2026 prefix supplies the opening reporting checkpoint.
    static func runPositions(_ options: V2WindowsOptions) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        func date(_ value: String) throws -> Date {
            guard let parsed = formatter.date(from: value) else {
                throw Error.invalidDate(value)
            }
            return parsed
        }

        let unit: MovementSelection.Unit
        switch options.unit {
        case "day": unit = .day
        case "week": unit = .week
        case "month": unit = .month
        case "quarter": unit = .quarter
        case "year": unit = .year
        default: throw Error.invalidUnit(options.unit)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let selection = try MovementSelection(
            anchor: date(options.anchor),
            unit: unit,
            count: options.count,
            calendar: calendar
        )

        let startOf2026 = try date("2026-01-01")
        let startOf2027 = try date("2027-01-01")
        let earliest = selection.windows[0].start
        guard earliest >= startOf2026,
              selection.windows[selection.windows.count - 1].end <= startOf2027
        else {
            throw Error.unsupportedFixtureWindow
        }

        let fixture = try V2ClosingFixture()
        let ledger = try fixture.sampleLedger()
        let previous = try Period(.init(
            ledger: ledger,
            start: date("2025-01-01"),
            end: startOf2026
        ))
        let audit = try Closing().evaluate(.init(
            period: previous, equityAccount: fixture.equity
        ))
        let composition = try Composition(.init(selection: .accept_closing(audit)))
        let compilation = try Compilation(.init(
            composition: composition, opening: .recorded
        ))
        let prior = try PositionState(
            compilation: compilation,
            provenance: Provenance(
                result: try Provenance.Identifier("ec_v2.fixture.2025.accepted"),
                inputs: []
            )
        )

        let checkpoint: PositionState
        if earliest == startOf2026 {
            checkpoint = prior
        } else {
            let prefix = try Period(.init(
                ledger: ledger, start: startOf2026, end: earliest
            ))
            let prefixComposition = try Composition(.init(
                selection: .recorded(prefix)
            ))
            checkpoint = try Continuity(.init(
                prior_state: prior,
                composition: prefixComposition,
                opening: .as_is,
                provenance: Provenance(
                    result: try Provenance.Identifier("ec_v2.fixture.prefix"),
                    inputs: [.calculation(prior.provenance.result)]
                )
            )).result
        }

        let slices = MovementSlices(.init(ledger: ledger, selection: selection))
        let source = try Provenance.Identifier("ec_v2.fixture.journal.1")
        let identifiers = try selection.windows.indices.map {
            try Provenance.Identifier("ec_v2.fixture.window.\($0)")
        }
        let lineages = selection.windows.indices.map { index in
            Provenance(
                result: identifiers[index],
                inputs: [
                    .calculation(index == 0 ? checkpoint.provenance.result : identifiers[index - 1]),
                    .source(source)
                ]
            )
        }
        let positions = try MovementPositions(.init(
            checkpoint: checkpoint,
            slices: slices,
            source: source,
            lineages: lineages
        ))

        print("ec_v2 positions | fixture=closing | unit=\(options.unit) count=\(positions.windows.count)")
        print("checkpoint=\(formatter.string(from: checkpoint.boundary)) recorded_before_postings=\(slices.recorded_before.postings.count) (not replayed)")
        for window in positions.windows {
            let role: String
            switch window.interval.role {
            case .previous: role = "previous"
            case .current: role = "current"
            case .offset(let index): role = "offset(\(index))"
            case .named(let value): role = value
            }
            print("\n\(role) | [\(formatter.string(from: window.interval.start)), \(formatter.string(from: window.interval.end))) movements=\(window.movements.postings.count)")
            for account in fixture.accountOrder {
                guard let amount = window.breakdown(for: account) else {
                    continue
                }
                print("\(account.code) | opening=\(amount.opening.posted) movements=\(amount.movements.posted) result=\(amount.result.posted) total=\(amount.result.total)")
            }
        }
    }
}
