import Foundation
import Writers

public extension DepreciationAuditRunner {

    /// Compile → audit depreciation → write missing monthly entries for `monthStart`.
    /// Returns number of entries written (0 if nothing to write).
    static func writeMissingForMonth(
        monthStart: Date,
        projectRoot: URL,
        tz: TimeZone,
        tolerance: Decimal,
        safe: SafeWriteOptions,
        verbose: Bool = false
    ) throws -> Int {

        // 1) Load project + settings
        let project  = EntryCompilerProject(root: projectRoot)
        let settings = try EntryCompilerSettingsLoader.load(from: projectRoot)

        // 2) Compile entities, accounts, entries (assertion: singular)
        let compiled = try EntryCompileDriver.compile(
            projectRoot: projectRoot,
            setting: .init(
                entities: true,
                accounts: true,
                transactions: true,
                entries: true,
                assertion: false
            ),
            verbose: verbose
        ) // compile driver labels: assertion (singular)

        // 3) Resolve entity depreciation configs for the writer
        //    (Audit runner also resolves internally; we keep a resolved copy for writing.)
        let entitiesResolved = try DepreciationResolutionPass.run(
            on: compiled.entities,
            using: compiled.accounts
        )

        // 4) Build audit options and run audit over resolved entries
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz

        let report = try DepreciationAuditRunner.run(
            entities: compiled.entities,
            accounts: compiled.accounts,
            resolvedEntries: compiled.resolved,
            through: nil,
            options: .init(
                granularity: .monthly,
                tolerance: tolerance,
                tolerateAggregateIntraQuarter: true,
                calendar: cal
            )
        )

        // 5) Write any missing postings for this month
        let wrote = try DepreciationEntryWriter.writeMissingForMonth(
            monthStart: monthStart,
            project: project,
            settings: settings,
            entities: entitiesResolved,
            report: report,
            projectRoot: projectRoot,
            options: .init(tz: tz, tolerance: tolerance, safe: safe),
            verbose: verbose
        )

        return wrote
    }
}
