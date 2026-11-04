import AccountingV2
import AccountingV2Fixtures
import Foundation

extension V2CommandRunner {
    enum BoundedError: Swift.Error {
        case parityMismatch(String)
    }

    static func runBounded() throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        func date(_ value: String) throws -> Date {
            guard let result = formatter.date(from: value) else {
                throw Error.invalidDate(value)
            }
            return result
        }

        let fixture = try V2ClosingFixture()
        let fullLedger = try fixture.sampleLedger()
        let source = try Provenance.Identifier("ec_v2.fixture.source")
        let revision = try Provenance.Identifier("ec_v2.fixture.revision.1")
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current
        let selection = try MovementSelection(
            anchor: date("2026-10-15"),
            unit: .month,
            calendar: calendar
        )
        let start = selection.windows[0].start
        let end = selection.windows[selection.windows.count - 1].end

        let earlier = try Period(.init(
            ledger: fullLedger,
            start: date("2025-01-01"),
            end: date("2026-01-01")
        ))
        let audit = try Closing().evaluate(.init(
            period: earlier,
            equityAccount: fixture.equity
        ))
        let composition = try Composition(.init(selection: .accept_closing(audit)))
        let compilation = try Compilation(.init(
            composition: composition,
            opening: .recorded
        ))
        let historical = try PositionState(
            compilation: compilation,
            provenance: Provenance(
                result: try Provenance.Identifier("ec_v2.bounded.2025"),
                inputs: [.sourceRevision(source: source, revision: revision)]
            )
        )
        let prefix = try Period(.init(
            ledger: fullLedger,
            start: date("2026-01-01"),
            end: start
        ))
        let prefixComposition = try Composition(.init(selection: .recorded(prefix)))
        let checkpoint = try Continuity(.init(
            prior_state: historical,
            composition: prefixComposition,
            opening: .as_is,
            provenance: Provenance(
                result: try Provenance.Identifier("ec_v2.bounded.checkpoint"),
                inputs: [
                    .calculation(historical.provenance.result),
                    .sourceRevision(source: source, revision: revision)
                ]
            )
        )).result

        let ids = try selection.windows.indices.map {
            try Provenance.Identifier("ec_v2.bounded.window.\($0)")
        }
        let lineages = selection.windows.indices.map { index in
            Provenance(
                result: ids[index],
                inputs: [
                    .calculation(index == 0 ? checkpoint.provenance.result : ids[index - 1]),
                    .source(source),
                    .sourceRevision(source: source, revision: revision)
                ]
            )
        }
        let full = try MovementPositions(.init(
            checkpoint: checkpoint,
            slices: MovementSlices(.init(
                ledger: fullLedger,
                selection: selection
            )),
            source: source,
            lineages: lineages
        ))

        let entries = fullLedger.journal.entries.filter {
            $0.date >= start && $0.date < end
        }
        let journal = try Journal(.init(
            entries: entries,
            chart: fixture.chart,
            entities: fixture.entities
        ))
        let boundedLedger = try Ledger(.init(journal: journal))
        let attested = try MovementSource(.init(
            ledger: boundedLedger,
            source: source,
            revision: revision,
            start: start,
            end: end
        ))
        let bounded = try MovementPositions(.init(
            checkpoint: checkpoint,
            selection: selection,
            source: attested,
            lineages: lineages
        ))

        print("ec_v2 bounded | fixture=closing | [\(formatter.string(from: start)), \(formatter.string(from: end)))")
        print("full_postings=\(fullLedger.postings.count) bounded_postings=\(boundedLedger.postings.count)")
        print("coverage_revision=\(revision.rawValue) checkpoint=\(formatter.string(from: checkpoint.boundary))")
        for (index, window) in bounded.windows.enumerated() {
            let counterpart = full.windows[index]
            for account in fixture.accountOrder {
                let expected = counterpart.result.amount(for: account)
                let actual = window.result.amount(for: account)
                guard expected?.posted == actual?.posted,
                      expected?.total == actual?.total else {
                    throw BoundedError.parityMismatch(account.code)
                }
            }
            let bank = window.result.amount(for: fixture.bank)?.posted ?? 0
            print("window=\(index) bank=\(bank) parity=passed")
        }
        print("bounded_parity=passed")
    }
}
