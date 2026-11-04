import AccountingV2
import AccountingV2Fixtures
import Foundation

/// Read-only CLI integration over the shared V2 fixture.
/// Real project adapters and reporting formats are deliberately separate.
enum V2CommandRunner {
    enum Error: Swift.Error {
        case invalidDate(String)
        case invalidUnit(String)
        case unsupportedFixtureWindow
    }

    private static func prepare(
        _ window: V2WindowOptions
    ) throws -> (fixture: V2ClosingFixture, period: Period) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        guard let start = formatter.date(from: window.start) else {
            throw Error.invalidDate(window.start)
        }
        guard let end = formatter.date(from: window.end) else {
            throw Error.invalidDate(window.end)
        }

        let fixture = try V2ClosingFixture()
        let ledger = try fixture.sampleLedger()
        let period = try Period(.init(
            ledger: ledger,
            start: start,
            end: end
        ))
        return (fixture, period)
    }

    static func runPeriod(_ options: V2PeriodOptions) throws {
        let (fixture, period) = try prepare(options.window)
        print("ec_v2 period | fixture=closing | [\(options.window.start), \(options.window.end))")
        print("ledger_postings=\(period.ledger.postings.count) opening_postings=\(period.opening.postings.count) movement_postings=\(period.movements.postings.count)")

        renderPeriod(fixture: fixture, period: period, entity: nil)
        if options.byEntity {
            for entity in fixture.entities.all {
                renderPeriod(
                    fixture: fixture,
                    period: period,
                    entity: entity.reference
                )
            }
        }
    }

    static func runCompile(_ options: V2CompileOptions) throws {
        let (fixture, period) = try prepare(options.window)
        let selection: Composition.Selection

        if options.closing {
            let audit = try Closing().evaluate(.init(
                period: period,
                equityAccount: fixture.equity
            ))
            selection = .accept_closing(audit)
        } else {
            selection = .recorded(period)
        }

        let composition = try Composition(.init(selection: selection))
        let compilation = try Compilation(.init(
            composition: composition,
            opening: options.carryforward ? .carryforward : .recorded
        ))
        let provenance = Provenance(
            result: try Provenance.Identifier("ec_v2.fixture.compilation"),
            inputs: [
                .source(try Provenance.Identifier("ec_v2.fixture.closing.1"))
            ]
        )
        let state = try PositionState(
            compilation: compilation,
            provenance: provenance
        )

        print("ec_v2 compile | fixture=closing | [\(options.window.start), \(options.window.end))")
        print("closing=\(options.closing ? "accepted" : "recorded-only") carryforward=\(options.carryforward ? "selected" : "recorded")")
        print("ledger_postings=\(period.ledger.postings.count) effects=\(composition.effects.count) state_cells=\(state.cells.count)")

        renderCompilation(fixture: fixture, compilation: compilation, state: state, entity: nil)
        if options.byEntity {
            for entity in fixture.entities.all {
                renderCompilation(
                    fixture: fixture,
                    compilation: compilation,
                    state: state,
                    entity: entity.reference
                )
            }
        }
        if options.trace {
            renderTrace(compilation: compilation)
        }
    }

    /// Resolve calendar comparison windows without creating fiscal periods.
    static func runWindows(_ options: V2WindowsOptions) throws {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let anchor = formatter.date(from: options.anchor) else {
            throw Error.invalidDate(options.anchor)
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
            anchor: anchor,
            unit: unit,
            count: options.count,
            calendar: calendar
        )
        let fixture = try V2ClosingFixture()
        let ledger = try fixture.sampleLedger()
        let slices = MovementSlices(.init(
            ledger: ledger,
            selection: selection
        ))

        print("ec_v2 windows | fixture=closing | unit=\(options.unit) count=\(selection.windows.count)")
        print("recorded_before_postings=\(slices.recorded_before.postings.count)")

        for window in slices.windows {
            let role: String
            switch window.interval.role {
            case .previous: role = "previous"
            case .current: role = "current"
            case .offset(let value): role = "offset(\(value))"
            case .named(let value): role = value
            }
            let start = formatter.string(from: window.interval.start)
            let end = formatter.string(from: window.interval.end)
            print("\n\(role) | [\(start), \(end)) postings=\(window.movements.postings.count)")
            for account in fixture.accountOrder {
                guard let amount = window.movements.amount(for: account) else {
                    continue
                }
                print("\(account.code) | posted=\(amount.posted) total=\(amount.total)")
            }
        }
    }

    /// Demonstrate actual accepted-state continuity across two financial years.
    /// The synthetic fixture is intentionally not a real project adapter.
    static func runContinuity() throws {
        let fixture = try V2ClosingFixture()
        let ledger = try fixture.sampleLedger()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        func date(_ value: String) throws -> Date {
            guard let result = formatter.date(from: value) else {
                throw Error.invalidDate(value)
            }
            return result
        }

        let earlier = try Period(.init(
            ledger: ledger,
            start: date("2025-01-01"),
            end: date("2026-01-01")
        ))
        let earlierAudit = try Closing().evaluate(.init(
            period: earlier,
            equityAccount: fixture.equity
        ))
        let earlierComposition = try Composition(.init(
            selection: .accept_closing(earlierAudit)
        ))
        let earlierCompilation = try Compilation(.init(
            composition: earlierComposition,
            opening: .recorded
        ))
        let priorProvenance = Provenance(
            result: try Provenance.Identifier("ec_v2.fixture.2025.closed"),
            inputs: []
        )
        let prior = try PositionState(
            compilation: earlierCompilation,
            provenance: priorProvenance
        )

        let current = try Period(.init(
            ledger: ledger,
            start: date("2026-01-01"),
            end: date("2027-01-01")
        ))
        let currentAudit = try Closing().evaluate(.init(
            period: current,
            equityAccount: fixture.equity
        ))
        let composition = try Composition(.init(
            selection: .accept_closing(currentAudit)
        ))
        let provenance = Provenance(
            result: try Provenance.Identifier("ec_v2.fixture.2026.closed"),
            inputs: [.calculation(prior.provenance.result)]
        )
        let continuity = try Continuity(.init(
            prior_state: prior,
            composition: composition,
            opening: .as_is,
            provenance: provenance
        ))

        print("ec_v2 continuity | fixture=closing | 2025 -> 2026")
        print("2025_effects=\(earlierAudit.effects.count) 2026_effects=\(currentAudit.effects.count)")
        print("prior_boundary=\(formatter.string(from: prior.boundary)) result_boundary=\(formatter.string(from: continuity.result.boundary))")
        for account in fixture.accountOrder {
            guard let breakdown = continuity.breakdown(for: account) else {
                continue
            }
            print("\(account.code) | prior=\(breakdown.prior.posted) opening=\(breakdown.opening.posted) movements=\(breakdown.movements.posted) calculated=\(breakdown.calculated.posted) result=\(breakdown.result.posted)")
        }
    }

    private static func renderPeriod(
        fixture: V2ClosingFixture,
        period: Period,
        entity: Entity.Reference?
    ) {
        print("\nACCOUNT PERIOD AMOUNTS | entity=\(entity?.identifier ?? "all")")
        for account in fixture.accountOrder {
            guard let opening = period.opening.amount(for: account, entity: entity),
                  let movements = period.movements.amount(for: account, entity: entity),
                  let position = period.position.amount(for: account, entity: entity)
            else { continue }
            print("\(account.code) | opening=\(opening.posted) movements=\(movements.posted) position=\(position.posted) total=\(position.total)")
        }
    }

    private static func renderCompilation(
        fixture: V2ClosingFixture,
        compilation: Compilation,
        state: PositionState,
        entity: Entity.Reference?
    ) {
        print("\nACCOUNT COMPILATION AMOUNTS | entity=\(entity?.identifier ?? "all")")
        for account in fixture.accountOrder {
            guard let breakdown = compilation.breakdown(for: account, entity: entity),
                  let materialized = state.amount(for: account, entity: entity)
            else { continue }
            print("\(account.code) | recorded_opening=\(breakdown.recorded_opening.posted) opening=\(breakdown.opening.posted) movements=\(breakdown.movements.posted) calculated=\(breakdown.calculated.posted) result=\(breakdown.result.posted) total=\(materialized.total)")
        }
    }

    private static func renderTrace(compilation: Compilation) {
        print("\nCALCULATED EFFECTS")
        for effect in compilation.composition.effects {
            let sources = effect.sources.map {
                "\($0.entryID.value):\($0.lineIndex)"
            }.joined(separator: ",")
            print("\(effect.kind) account=\(effect.account.code) entity=\(effect.entity.identifier) signed=\(effect.signedAmount) sources=[\(sources)]")
        }

        print("\nCARRYFORWARD CONTRIBUTIONS")
        if let routing = compilation.routing {
            for contribution in routing.contributions {
                print("entry=\(contribution.source.entryID.value) line=\(contribution.source.lineIndex) from=\(contribution.originalAccount.code) to=\(contribution.destination.code) signed=\(contribution.signedAmount)")
            }
        } else {
            print("recorded opening selected; no routing applied")
        }
    }
}
