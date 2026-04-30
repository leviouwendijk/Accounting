import Accounting
import Arguments
import Foundation
import Writers

enum DepreciationDetailMode: String, Sendable, ArgumentValue {
    case monthly
    case periods
    case full
}

enum DepreciationCommand: BoundArgumentCommand {
    static let name = "depreciation"

    static let children: [ArgumentCommandType] = [
        Write.self,
        Clean.self,
    ]

    struct Options: ArgumentGroup {
        @Group("project")
        var project: ProjectOptions

        @Flag(
            "verbose",
            short: "v"
        )
        var verbose: Bool

        @Opt(
            "detail",
            default: .monthly
        )
        var detail: DepreciationDetailMode

        @Opt(
            "tolerance",
            short: "t",
            default: Decimal(0)
        )
        var tolerance: Decimal

        init() {}
    }

    static func run(
        _ options: Options,
        invocation: ParsedInvocation
    ) async throws {
        let provided = URL(
            fileURLWithPath: options.project.resolvedPath,
            isDirectory: true
        )

        let root = EntryCompilerProject.findRoot(
            startingAt: provided
        ) ?? provided

        let report = try DepreciationAuditRunner.run(
            projectRoot: root,
            verbose: options.verbose,
            options: .init(
                granularity: .monthly,
                tolerance: options.tolerance,
                tolerateAggregateIntraQuarter: true
            )
        )

        let textOptions: DepreciationAuditTextOptions = {
            switch options.detail {
            case .monthly:
                return .init(
                    showPerYearAmounts: true,
                    showPerMonthAmounts: true,
                    showPerPeriodAmounts: false
                )

            case .periods:
                return .init(
                    showPerYearAmounts: true,
                    showPerMonthAmounts: true,
                    showPerPeriodAmounts: true
                )

            case .full:
                return .init(
                    showFailuresEvenIfCovered: true,
                    showPerYearAmounts: true,
                    showPerMonthAmounts: true,
                    showPerPeriodAmounts: true
                )
            }
        }()

        print(
            report.renderText(
                textOptions
            )
        )
    }

    struct Write: BoundArgumentCommand {
        static let name = "write"

        struct Options: ArgumentGroup {
            @Group("project")
            var project: ProjectOptions

            @Opt("month")
            var month: String?

            @Opt("timezone")
            var timezone: String?

            @Opt(
                "tolerance",
                default: Decimal(0)
            )
            var tolerance: Decimal

            @Flag(
                "verbose",
                short: "v"
            )
            var verbose: Bool

            @Flag("abort")
            var abort: Bool

            @Flag("replace")
            var replace: Bool

            @Flag("backup")
            var backup: Bool

            @Flag("whitespace-only-is-blank")
            var whitespaceOnlyIsBlank: Bool

            @Opt(
                "backup-suffix",
                default: "_previous_version.bak"
            )
            var backupSuffix: String

            @Flag("all")
            var all: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let start = URL(
                fileURLWithPath: options.project.resolvedPath,
                isDirectory: true
            )

            guard let root = EntryCompilerProject.findRoot(
                startingAt: start
            ) else {
                throw EntryCompilerCLIError.validation(
                    "Could not locate project root starting at: \(start.path)"
                )
            }

            let project = EntryCompilerProject(
                root: root
            )

            let settings = try EntryCompilerSettingsLoader.load(
                from: root
            )

            let timeZone = options.timezone.flatMap(
                TimeZone.init(identifier:)
            ) ?? settings.entry.defaultTimezone

            let compiled = try await EntryCompileDriver.compile(
                projectRoot: root,
                setting: .init(
                    entities: true,
                    accounts: true,
                    transactions: true,
                    entries: true,
                    assertion: false
                ),
                verbose: options.verbose,
                placeholderWarnings: options.verbose ? .perEntry : .summary
            )

            let entitiesResolved = try DepreciationResolutionPass.run(
                on: compiled.entities,
                using: compiled.accounts
            )

            var calendar = Calendar(
                identifier: .gregorian
            )
            calendar.timeZone = timeZone

            let report = try DepreciationAuditRunner.run(
                entities: entitiesResolved,
                accounts: compiled.accounts,
                resolvedEntries: compiled.resolved,
                through: nil,
                options: .init(
                    granularity: .monthly,
                    tolerance: options.tolerance,
                    tolerateAggregateIntraQuarter: true,
                    calendar: calendar
                )
            )

            let failing = report.items.filter { item in
                item.coverage == .none && item.expected > item.actual
            }

            let failingMonths = Array(
                Set(
                    failing.map { item in
                        DepreciationPostingWindow.postingMonthStart(
                            for: item,
                            calendar: calendar
                        )
                    }
                )
            )
            .sorted()

            let targets: [Date]

            if let month = options.month {
                targets = [
                    try parseDepreciationMonthStart(
                        month,
                        calendar: calendar
                    ),
                ]
            } else if options.all {
                targets = failingMonths.isEmpty
                    ? [
                        DepreciationPostingWindow.monthStart(
                            for: DepreciationAuditHorizon.endOfMonth(
                                using: compiled.resolved,
                                calendar: calendar
                            ),
                            calendar: calendar
                        ),
                    ]
                    : failingMonths
            } else if let earliestFail = failingMonths.first {
                if options.verbose {
                    print("Auto-selecting earliest failing month: \(earliestFail)")
                }

                targets = [
                    earliestFail,
                ]
            } else {
                targets = [
                    DepreciationPostingWindow.monthStart(
                        for: DepreciationAuditHorizon.endOfMonth(
                            using: compiled.resolved,
                            calendar: calendar
                        ),
                        calendar: calendar
                    ),
                ]
            }

            let safeOptions = SafeWriteOptions(
                existingFilePolicy: options.abort ? .abort : .overwrite,
                makeBackupOnOverride: options.backup,
                whitespaceOnlyIsBlank: options.whitespaceOnlyIsBlank,
                backupSuffix: options.backupSuffix
            )

            var total = 0

            for target in targets {
                let wrote = try DepreciationEntryWriter.writeMissingForMonth(
                    monthStart: target,
                    project: project,
                    settings: settings,
                    entities: entitiesResolved,
                    report: report,
                    projectRoot: root,
                    options: .init(
                        tz: timeZone,
                        tolerance: options.tolerance,
                        safe: safeOptions,
                        contentOverwriteMode: options.replace ? .replace : .append
                    ),
                    verbose: options.verbose
                )

                let year = calendar.component(
                    .year,
                    from: target
                )

                let month = calendar.component(
                    .month,
                    from: target
                )

                if wrote == 0 {
                    if options.verbose {
                        print("Nothing to write for \(year)-\(String(format: "%02d", month)).")
                    }
                } else {
                    print("Wrote \(wrote) entr\(wrote == 1 ? "y" : "ies") for \(year)-\(String(format: "%02d", month)).")
                }

                total += wrote
            }

            if total == 0,
               !options.verbose,
               targets.count == 1 {
                let target = targets[0]

                let year = calendar.component(
                    .year,
                    from: target
                )

                let month = calendar.component(
                    .month,
                    from: target
                )

                print("No missing depreciation to write for \(year)-\(String(format: "%02d", month)) (≤ tol or already covered).")
            }
        }
    }

    struct Clean: BoundArgumentCommand {
        static let name = "clean"

        struct Options: ArgumentGroup {
            @Group("project")
            var project: ProjectOptions

            @Flag("all")
            var all: Bool

            @Opt("year")
            var year: Int?

            @Opt("month")
            var month: String?

            @Opt("from")
            var from: String?

            @Opt("to")
            var to: String?

            @Flag(
                "yes",
                short: "y"
            )
            var yes: Bool

            @Flag(
                "verbose",
                short: "v"
            )
            var verbose: Bool

            init() {}
        }

        static func run(
            _ options: Options,
            invocation: ParsedInvocation
        ) async throws {
            let selectedModes = [
                options.all,
                options.year != nil,
                options.month != nil,
                options.from != nil || options.to != nil,
            ]
            .filter { $0 }
            .count

            guard selectedModes == 1 else {
                throw EntryCompilerCLIError.validation(
                    "Choose exactly one scope: --all, --year, --month, or --from/--to."
                )
            }

            if let year = options.year,
               year < 1 {
                throw EntryCompilerCLIError.validation(
                    "--year must be a positive integer."
                )
            }

            let start = URL(
                fileURLWithPath: options.project.resolvedPath,
                isDirectory: true
            )

            guard let root = EntryCompilerProject.findRoot(
                startingAt: start
            ) else {
                throw EntryCompilerCLIError.validation(
                    "Could not locate project root starting at: \(start.path)"
                )
            }

            let entriesRoot = root
                .appendingPathComponent(
                    "entries",
                    isDirectory: true
                )

            let trashRoot = root
                .appendingPathComponent(
                    "archive",
                    isDirectory: true
                )
                .appendingPathComponent(
                    "trash",
                    isDirectory: true
                )

            let scope = try DepreciationCleanScope(
                all: options.all,
                year: options.year,
                month: options.month,
                from: options.from,
                to: options.to
            )

            let candidates = try collectDepreciationCleanCandidates(
                entriesRoot: entriesRoot,
                trashRoot: trashRoot,
                scope: scope
            )

            guard !candidates.isEmpty else {
                print("No matching depreciation.ec files found.")
                return
            }

            print("Depreciation clean")
            print("This only moves files literally named depreciation.ec under entries/.")
            print("No other files will be touched.")
            print("")
            print("Found \(candidates.count) file\(candidates.count == 1 ? "" : "s"):")
            print("")

            for candidate in candidates {
                print("  \(candidate.source.path)")
                print("    -> \(candidate.archiveDestination.path)")
            }

            if !options.yes {
                print("")
                print("Proceed and move these files to archive/trash? Type yes or no:", terminator: " ")

                let confirmed = readLine(strippingNewline: true)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == "yes"

                guard confirmed else {
                    print("Cancelled.")
                    return
                }
            }

            let fileManager = FileManager.default
            var movedCount = 0

            for candidate in candidates {
                let destination = makeUniqueArchiveDestination(
                    desired: candidate.archiveDestination,
                    fileManager: fileManager
                )

                try fileManager.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )

                try fileManager.moveItem(
                    at: candidate.source,
                    to: destination
                )

                movedCount += 1

                if options.verbose {
                    print("Moved \(candidate.source.path) -> \(destination.path)")
                }
            }

            print("")
            print("Moved \(movedCount) depreciation file\(movedCount == 1 ? "" : "s").")
        }
    }
}

private struct DepreciationMonthKey: Comparable, Equatable {
    let year: Int
    let month: Int

    static func < (
        lhs: DepreciationMonthKey,
        rhs: DepreciationMonthKey
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        return lhs.month < rhs.month
    }

    static func parse(
        _ raw: String,
        label: String
    ) throws -> DepreciationMonthKey {
        let parts = raw
            .split(separator: "-", maxSplits: 1)
            .map(String.init)

        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              (1...12).contains(month) else {
            throw EntryCompilerCLIError.validation(
                "Invalid \(label) value '\(raw)'. Use YYYY-MM."
            )
        }

        return DepreciationMonthKey(
            year: year,
            month: month
        )
    }
}

private func parseDepreciationMonthStart(
    _ raw: String,
    calendar: Calendar
) throws -> Date {
    let key = try DepreciationMonthKey.parse(
        raw,
        label: "--month"
    )

    guard let date = calendar.date(
        from: DateComponents(
            year: key.year,
            month: key.month,
            day: 1
        )
    ) else {
        throw EntryCompilerCLIError.validation(
            "Invalid --month \(raw). Use YYYY-MM."
        )
    }

    return date
}

private enum DepreciationCleanScope {
    case all
    case year(Int)
    case singleMonth(DepreciationMonthKey)
    case range(
        lower: DepreciationMonthKey?,
        upper: DepreciationMonthKey?
    )

    init(
        all: Bool,
        year: Int?,
        month: String?,
        from: String?,
        to: String?
    ) throws {
        if all {
            self = .all
            return
        }

        if let year {
            self = .year(year)
            return
        }

        if let month {
            self = .singleMonth(
                try DepreciationMonthKey.parse(
                    month,
                    label: "--month"
                )
            )
            return
        }

        let lower = try from.map {
            try DepreciationMonthKey.parse(
                $0,
                label: "--from"
            )
        }

        let upper = try to.map {
            try DepreciationMonthKey.parse(
                $0,
                label: "--to"
            )
        }

        if let lower,
           let upper,
           upper < lower {
            throw EntryCompilerCLIError.validation(
                "--to must be greater than or equal to --from."
            )
        }

        self = .range(
            lower: lower,
            upper: upper
        )
    }

    func matches(
        year: Int,
        month: Int
    ) -> Bool {
        let key = DepreciationMonthKey(
            year: year,
            month: month
        )

        switch self {
        case .all:
            return true

        case .year(let targetYear):
            return year == targetYear

        case .singleMonth(let target):
            return key == target

        case .range(let lower, let upper):
            if let lower,
               key < lower {
                return false
            }

            if let upper,
               key > upper {
                return false
            }

            return true
        }
    }
}

private struct DepreciationCleanCandidate: Comparable {
    let source: URL
    let archiveDestination: URL
    let year: Int
    let quarter: Int
    let month: Int

    static func < (
        lhs: DepreciationCleanCandidate,
        rhs: DepreciationCleanCandidate
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }

        return lhs.source.path < rhs.source.path
    }
}

private func collectDepreciationCleanCandidates(
    entriesRoot: URL,
    trashRoot: URL,
    scope: DepreciationCleanScope
) throws -> [DepreciationCleanCandidate] {
    let fileManager = FileManager.default

    guard let enumerator = fileManager.enumerator(
        at: entriesRoot,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    ) else {
        return []
    }

    let baseComponents = entriesRoot.standardizedFileURL.pathComponents
    var candidates: [DepreciationCleanCandidate] = []

    for case let fileURL as URL in enumerator {
        guard fileURL.lastPathComponent == "depreciation.ec" else {
            continue
        }

        let standardized = fileURL.standardizedFileURL
        let components = standardized.pathComponents

        guard components.count >= baseComponents.count else {
            continue
        }

        let relative = Array(
            components.dropFirst(baseComponents.count)
        )

        guard relative.count == 4,
              relative[3] == "depreciation.ec",
              let year = Int(relative[0]),
              let quarter = parseDepreciationQuarterDirectory(relative[1]),
              let month = Int(relative[2]),
              (1...4).contains(quarter),
              (1...12).contains(month),
              scope.matches(
                year: year,
                month: month
              ) else {
            continue
        }

        let expectedQuarter = ((month - 1) / 3) + 1
        guard quarter == expectedQuarter else {
            continue
        }

        let destination = trashRoot
            .appendingPathComponent(
                relative[0],
                isDirectory: true
            )
            .appendingPathComponent(
                relative[1],
                isDirectory: true
            )
            .appendingPathComponent(
                relative[2],
                isDirectory: true
            )
            .appendingPathComponent(
                relative[3],
                isDirectory: false
            )

        candidates.append(
            DepreciationCleanCandidate(
                source: standardized,
                archiveDestination: destination.standardizedFileURL,
                year: year,
                quarter: quarter,
                month: month
            )
        )
    }

    return candidates.sorted()
}

private func parseDepreciationQuarterDirectory(
    _ value: String
) -> Int? {
    if value.lowercased().hasPrefix("q") {
        return Int(value.dropFirst())
    }

    return Int(value)
}

private func makeUniqueArchiveDestination(
    desired: URL,
    fileManager: FileManager
) -> URL {
    guard fileManager.fileExists(
        atPath: desired.path
    ) else {
        return desired
    }

    let directory = desired.deletingLastPathComponent()
    let base = desired.deletingPathExtension().lastPathComponent
    let ext = desired.pathExtension
    let timestamp = archiveTimestampString()

    var attempt = 0

    while true {
        let suffix = attempt == 0
            ? "-\(timestamp)"
            : "-\(timestamp)-\(attempt)"

        var candidate = directory.appendingPathComponent(
            base + suffix,
            isDirectory: false
        )

        if !ext.isEmpty {
            candidate = candidate.appendingPathExtension(
                ext
            )
        }

        if !fileManager.fileExists(
            atPath: candidate.path
        ) {
            return candidate
        }

        attempt += 1
    }
}

private func archiveTimestampString() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(
        from: Date()
    )
}
