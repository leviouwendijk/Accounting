import Foundation

public enum AssetsOverviewBuilder {
    public static func build(
        result: EntryCompileDriver.Result,
        period: PeriodWindow,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) throws -> AssetsOverview {
        let entities = try DepreciationResolutionPass.run(
            on: result.entities,
            using: result.accounts
        )

        let closingAsOf = period.to ?? DepreciationAuditHorizon.endOfMonth(
            using: result.resolved,
            calendar: calendar
        )

        let openingAsOf = period.from.flatMap {
            calendar.date(byAdding: .day, value: -1, to: $0)
        }

        var rows: [AssetsOverviewRow] = []
        var diagnosticCounts: [String: Int] = [:]

        for (key, entity) in entities.pairs() {
            if shouldExcludeFromAssetsOverview(entity: entity) {
                continue
            }

            guard isAssetCandidate(
                key: key,
                entity: entity
            ) else {
                continue
            }

            let depreciation = entity.depreciation

            let profileAccess = try? DepreciationProfileAccess.resolve(
                for: key,
                entity: entity,
                fallbackSchedule: depreciation?.schedule,
                fallbackAcquisition: depreciation?.acquistion
            )

            let displayName = normalizedDisplayName(
                key: key,
                entity: entity
            )

            let details = normalizedDetails(
                from: entity
            )

            let acquisitionDate = profileAccess?.acquisitionDate
            let commissionDate = entity.profile?.commissionDate
            let effectiveStartDate = profileAccess?.commissionDate
            let acquisitionCost = profileAccess?.acquisition.cost

            let rawCategory = rawAssetCategory(
                entity: entity
            )
            let category = category(
                entity: entity
            )

            if let effectiveStartDate, effectiveStartDate > closingAsOf {
                continue
            }

            let (ownerShares, shareIssues) = resolveShares(
                entity: entity,
                totalAmount: acquisitionCost
            )

            let openingCarryingAmount = carryingAmount(
                asOf: openingAsOf,
                acquisitionCost: acquisitionCost,
                depreciation: depreciation,
                availableFrom: effectiveStartDate,
                calendar: calendar
            )

            let periodInvestment = investmentAmount(
                acquisitionCost: acquisitionCost,
                investmentDate: effectiveStartDate,
                in: period
            )

            let periodDepreciation = depreciationAmount(
                depreciation: depreciation,
                availableFrom: effectiveStartDate,
                in: period,
                closingAsOf: closingAsOf,
                calendar: calendar
            )

            // let periodDepreciation = depreciationAmount(
            //     depreciation: depreciation,
            //     in: period,
            //     closingAsOf: closingAsOf,
            //     calendar: calendar
            // )

            let closingCarryingAmount = carryingAmount(
                asOf: closingAsOf,
                acquisitionCost: acquisitionCost,
                depreciation: depreciation,
                availableFrom: effectiveStartDate,
                calendar: calendar
            )

            var issues: [AssetsOverviewIssue] = []

            issues.append(contentsOf: schemaIssues(
                key: key,
                entity: entity,
                depreciation: depreciation,
                profileAccessResolved: profileAccess != nil,
                rawCategory: rawCategory,
                category: category,
                details: details,
                acquisitionDate: acquisitionDate,
                effectiveStartDate: effectiveStartDate,
                acquisitionCost: acquisitionCost,
                ownerShares: ownerShares,
                shareIssues: shareIssues
            ))

            let preRow = AssetsOverviewRow(
                entityKey: key,
                displayName: displayName,
                details: details,
                category: category,
                type: typeLabel(
                    key: key,
                    entity: entity
                ),
                acquisitionDate: acquisitionDate,
                commissionDate: commissionDate,
                acquisitionCost: acquisitionCost,
                usefulLifeYears: depreciation?.schedule.usefulLifeYears,
                residualPercentage: depreciation.map {
                    $0.residual.percentNormalized * 100
                },
                residualAmount: depreciation?.residual.amount,
                depreciationAccountCode: depreciation?.account.code,
                contraAccountCode: depreciation?.contra.code,
                openingCarryingAmount: openingCarryingAmount,
                periodInvestment: periodInvestment,
                periodDepreciation: periodDepreciation,
                closingCarryingAmount: closingCarryingAmount,
                ownerShares: ownerShares,
                issues: []
            )

            if category == .unclassified && hasNonZeroFilingAmounts(row: preRow) {
                issues.append(
                    .init(
                        severity: .error,
                        message: "unclassified non-zero filing asset"
                    )
                )
            }

            issues = uniqueIssues(issues)

            let row = AssetsOverviewRow(
                entityKey: key,
                displayName: displayName,
                details: details,
                category: category,
                type: typeLabel(
                    key: key,
                    entity: entity
                ),
                acquisitionDate: acquisitionDate,
                commissionDate: commissionDate,
                acquisitionCost: acquisitionCost,
                usefulLifeYears: depreciation?.schedule.usefulLifeYears,
                residualPercentage: depreciation.map {
                    $0.residual.percentNormalized * 100
                },
                residualAmount: depreciation?.residual.amount,
                depreciationAccountCode: depreciation?.account.code,
                contraAccountCode: depreciation?.contra.code,
                openingCarryingAmount: openingCarryingAmount,
                periodInvestment: periodInvestment,
                periodDepreciation: periodDepreciation,
                closingCarryingAmount: closingCarryingAmount,
                ownerShares: ownerShares,
                issues: issues
            )

            if shouldSuppressDiagnosticNoise(row: row, entity: entity) {
                continue
            }

            rows.append(row)

            for issue in row.issues {
                diagnosticCounts[issue.message, default: 0] += 1
            }
        }

        rows.sort(by: sortRows)

        let rowsByCategory: [AssetsOverviewCategory: [AssetsOverviewRow]] = Dictionary(
            grouping: rows,
            by: { (row: AssetsOverviewRow) in row.category }
        )

        let lines: [AssetsOverviewLine] = AssetsOverviewFormLine.all.compactMap {
            (formLine: AssetsOverviewFormLine) -> AssetsOverviewLine? in
            let categoryRows: [AssetsOverviewRow] = rowsByCategory[formLine.category] ?? []

            if formLine.category == .unclassified && categoryRows.isEmpty {
                return nil
            }

            return AssetsOverviewLine(
                category: formLine.category,
                name: formLine.label,
                rows: categoryRows,
                flaggedAssetCount: categoryRows.filter(\.hasIssues).count,
                totals: makeAmounts(from: categoryRows)
            )
        }

        let linesBySection: [AssetsOverviewSection: [AssetsOverviewLine]] = Dictionary(
            grouping: lines,
            by: { (line: AssetsOverviewLine) in line.category.section }
        )

        let groups: [AssetsOverviewGroup] = AssetsOverviewSection.allCases
            .sorted { lhs, rhs in
                lhs.sortOrder < rhs.sortOrder
            }
            .compactMap { section in
                let sectionLines: [AssetsOverviewLine] = (linesBySection[section] ?? [])
                    .sorted { lhs, rhs in
                        lhs.category.sortOrder < rhs.category.sortOrder
                    }

                if section == .unclassified && sectionLines.isEmpty {
                    return nil
                }

                let sectionRows: [AssetsOverviewRow] = sectionLines.flatMap(\.rows)

                return AssetsOverviewGroup(
                    section: section,
                    name: section.label,
                    totalLabel: section.totalLabel,
                    lines: sectionLines,
                    flaggedAssetCount: sectionRows.filter(\.hasIssues).count,
                    totals: makeAmounts(from: sectionRows)
                )
            }

        let unclassifiedNonZeroRows = rows.filter { row in
            row.category == .unclassified && hasNonZeroFilingAmounts(row: row)
        }

        if !unclassifiedNonZeroRows.isEmpty {
            diagnosticCounts["unclassified non-zero assets", default: 0] = unclassifiedNonZeroRows.count
        }

        let summary = AssetsOverviewSummary(
            assetCount: rows.count,
            flaggedAssetCount: rows.filter(\.hasIssues).count,
            totals: makeAmounts(from: rows),
            unclassifiedNonZeroAssetCount: unclassifiedNonZeroRows.count,
            unclassifiedNonZeroTotals: makeAmounts(from: unclassifiedNonZeroRows),
            unclassifiedNonZeroRows: unclassifiedNonZeroRows
        )

        return AssetsOverview(
            period: period,
            rows: rows,
            groups: groups,
            summary: summary,
            diagnosticCounts: diagnosticCounts
        )
    }

    private static func makeAmounts(
        from rows: [AssetsOverviewRow]
    ) -> AssetsOverviewAmounts {
        AssetsOverviewAmounts(
            acquisitionCost: rows.reduce(0) { $0 + ($1.acquisitionCost ?? 0) },
            openingCarryingAmount: rows.reduce(0) { $0 + $1.openingCarryingAmount },
            periodInvestment: rows.reduce(0) { $0 + $1.periodInvestment },
            periodDepreciation: rows.reduce(0) { $0 + $1.periodDepreciation },
            closingCarryingAmount: rows.reduce(0) { $0 + $1.closingCarryingAmount },
            residualAmount: rows.reduce(0) { $0 + ($1.residualAmount ?? 0) }
        )
    }

    private static func schemaIssues(
        key: EntityKey,
        entity: EntityDef,
        depreciation: DepreciationConfig?,
        profileAccessResolved: Bool,
        rawCategory: String?,
        category: AssetsOverviewCategory,
        details: String?,
        acquisitionDate: Date?,
        effectiveStartDate: Date?,
        acquisitionCost: Decimal?,
        ownerShares: [KIAAssetShare],
        shareIssues: [AssetsOverviewIssue]
    ) -> [AssetsOverviewIssue] {
        var issues: [AssetsOverviewIssue] = []

        if !profileAccessResolved {
            issues.append(
                .init(
                    severity: .error,
                    message: "missing depreciation/profile data"
                )
            )
        } else {
            if entity.profile == nil {
                issues.append(
                    .init(
                        severity: .warning,
                        message: "uses legacy depreciation fallback"
                    )
                )
            }

            if depreciation == nil {
                issues.append(
                    .init(
                        severity: .warning,
                        message: "missing depreciation config"
                    )
                )
            }
        }

        if acquisitionDate == nil && effectiveStartDate == nil {
            issues.append(
                .init(
                    severity: .error,
                    message: "missing commission/acquisition date"
                )
            )
        }

        if acquisitionCost == nil || acquisitionCost == 0 {
            issues.append(
                .init(
                    severity: .error,
                    message: "missing acquisition cost"
                )
            )
        }

        if details == nil {
            issues.append(
                .init(
                    severity: .warning,
                    message: "missing details"
                )
            )
        }

        if rawCategory == nil {
            issues.append(
                .init(
                    severity: .error,
                    message: "missing asset_category"
                )
            )
        } else if category == .unclassified,
                  rawCategory?.lowercased() != "unclassified" {
            issues.append(
                .init(
                    severity: .error,
                    message: "invalid asset_category: \(rawCategory!)"
                )
            )
        }

        if hasRollforwardMetadata(entity: entity) {
            issues.append(
                .init(
                    severity: .warning,
                    message: "contains depreciation rollforward metadata; not yet applied in this view"
                )
            )
        }

        if hasPrivateUseSignal(
            key: key,
            entity: entity
        ) {
            issues.append(
                .init(
                    severity: .warning,
                    message: "possible private-use / bijtelling relevance"
                )
            )
        }

        if hasPlaceholderIdentity(
            key: key,
            entity: entity
        ) {
            issues.append(
                .init(
                    severity: .info,
                    message: "placeholder-like asset identity"
                )
            )
        }

        issues.append(contentsOf: shareIssues)

        if ownerShares.isEmpty {
            issues.append(
                .init(
                    severity: .warning,
                    message: "no owner-share allocation"
                )
            )
        } else if ownerShares.allSatisfy({ $0.owner == nil }) {
            issues.append(
                .init(
                    severity: .warning,
                    message: "unassigned owner-share allocation"
                )
            )
        }

        return issues
    }

    private static func hasNonZeroFilingAmounts(
        row: AssetsOverviewRow
    ) -> Bool {
        (row.acquisitionCost ?? 0) != 0
            || row.openingCarryingAmount != 0
            || row.periodInvestment != 0
            || row.periodDepreciation != 0
            || row.closingCarryingAmount != 0
            || (row.residualAmount ?? 0) != 0
    }

    @inline(__always)
    private static func shouldExcludeFromAssetsOverview(
        entity: EntityDef
    ) -> Bool {
        guard let raw = cleaned(entity.metadata["asset_overview"])?.lowercased() else {
            return false
        }

        return raw == "exclude"
    }

    @inline(__always)
    private static func isAssetCandidate(
        key: EntityKey,
        entity: EntityDef
    ) -> Bool {
        if key.class == "objects" && key.family == "usable" {
            return true
        }

        if entity.profile != nil {
            return true
        }

        if entity.kia != nil || entity.kiaDraft != nil {
            return true
        }

        if entity.depreciation != nil || entity.depreciationDraft != nil {
            return true
        }

        return false
    }

    private static func shouldSuppressDiagnosticNoise(
        row: AssetsOverviewRow,
        entity: EntityDef
    ) -> Bool {
        if hasNonZeroFilingAmounts(row: row) {
            return false
        }

        if row.category != .unclassified {
            return false
        }

        if entity.profile != nil || entity.depreciation != nil || entity.kia != nil || entity.kiaDraft != nil {
            return false
        }

        if row.ownerShares.isEmpty == false {
            return false
        }

        let onlyNoise = row.issues.allSatisfy { issue in
            switch issue.message {
            case "uses legacy depreciation fallback",
                 "missing depreciation config",
                 "missing depreciation/profile data",
                 "missing commission/acquisition date",
                 "missing acquisition cost",
                 "missing details",
                 "missing asset_category",
                 "no owner-share allocation",
                 "placeholder-like asset identity":
                return true

            default:
                return false
            }
        }

        return onlyNoise
    }

    private static func carryingAmount(
        asOf: Date?,
        acquisitionCost: Decimal?,
        depreciation: DepreciationConfig?,
        availableFrom: Date?,
        calendar: Calendar
    ) -> Decimal {
        guard let acquisitionCost,
              acquisitionCost > 0
        else {
            return 0
        }

        guard let asOf else {
            return 0
        }

        if let availableFrom, asOf < availableFrom {
            return 0
        }

        guard let depreciation else {
            return acquisitionCost
        }

        guard let availableFrom else {
            return acquisitionCost
        }

        let slices = depreciation.project(
            through: asOf,
            startDate: availableFrom,
            startConvention: .firstFullMonth,
            granularity: .monthly,
            calendar: calendar
        )

        return slices.last?.nbvClosing ?? acquisitionCost
    }

    // private static func carryingAmount(
    //     asOf: Date?,
    //     acquisitionCost: Decimal?,
    //     depreciation: DepreciationConfig?,
    //     availableFrom: Date?,
    //     calendar: Calendar
    // ) -> Decimal {
    //     guard let acquisitionCost,
    //           acquisitionCost > 0
    //     else {
    //         return 0
    //     }

    //     guard let asOf else {
    //         return 0
    //     }

    //     if let availableFrom, asOf < availableFrom {
    //         return 0
    //     }

    //     guard let depreciation else {
    //         return acquisitionCost
    //     }

    //     if asOf < depreciation.schedule.effectiveDate {
    //         return acquisitionCost
    //     }

    //     let slices = depreciation.project(
    //         through: asOf,
    //         granularity: .monthly,
    //         calendar: calendar
    //     )

    //     return slices.last?.nbvClosing ?? acquisitionCost
    // }

    private static func investmentAmount(
        acquisitionCost: Decimal?,
        investmentDate: Date?,
        in period: PeriodWindow
    ) -> Decimal {
        guard let acquisitionCost,
              acquisitionCost > 0,
              let investmentDate
        else {
            return 0
        }

        return contains(investmentDate, in: period)
            ? acquisitionCost
            : 0
    }

    private static func depreciationAmount(
        depreciation: DepreciationConfig?,
        availableFrom: Date?,
        in period: PeriodWindow,
        closingAsOf: Date,
        calendar: Calendar
    ) -> Decimal {
        guard let depreciation else {
            return 0
        }

        guard let availableFrom else {
            return 0
        }

        let slices = depreciation.project(
            through: closingAsOf,
            startDate: availableFrom,
            startConvention: .firstFullMonth,
            granularity: .monthly,
            calendar: calendar
        )

        return slices.reduce(0) { partial, slice in
            let postingDate = postingDate(
                for: slice,
                calendar: calendar
            )

            if contains(postingDate, in: period) {
                return partial + slice.depreciation
            }

            return partial
        }
    }

    // private static func depreciationAmount(
    //     depreciation: DepreciationConfig?,
    //     in period: PeriodWindow,
    //     closingAsOf: Date,
    //     calendar: Calendar
    // ) -> Decimal {
    //     guard let depreciation else {
    //         return 0
    //     }

    //     let slices = depreciation.project(
    //         through: closingAsOf,
    //         granularity: .monthly,
    //         calendar: calendar
    //     )

    //     return slices.reduce(0) { partial, slice in
    //         let postingDate = postingDate(
    //             for: slice,
    //             calendar: calendar
    //         )

    //         if contains(postingDate, in: period) {
    //             return partial + slice.depreciation
    //         }

    //         return partial
    //     }
    // }

    @inline(__always)
    private static func postingDate(
        for slice: DepreciationSlice,
        calendar: Calendar
    ) -> Date {
        calendar.date(
            byAdding: .second,
            value: -1,
            to: slice.periodEnd
        ) ?? slice.periodEnd
    }

    private static func resolveShares(
        entity: EntityDef,
        totalAmount: Decimal?
    ) -> ([KIAAssetShare], [AssetsOverviewIssue]) {
        if let kia = entity.kia {
            let shares = kia.shares.map { share in
                KIAAssetShare(
                    owner: share.owner,
                    ownerLabel: ownerLabel(for: share.owner),
                    percentage: share.percentage,
                    amount: share.amount
                )
            }

            return (shares, [])
        }

        if let kiaDraft = entity.kiaDraft {
            guard let totalAmount,
                  totalAmount > 0
            else {
                return (
                    [],
                    [
                        .init(
                            severity: .error,
                            message: "cannot resolve draft owner-share allocation without acquisition cost"
                        )
                    ]
                )
            }

            do {
                let resolved = try kiaDraft.resolve(
                    acquisitionCost: totalAmount
                )

                let shares = resolved.shares.map { share in
                    KIAAssetShare(
                        owner: share.owner,
                        ownerLabel: ownerLabel(for: share.owner),
                        percentage: share.percentage,
                        amount: share.amount
                    )
                }

                return (shares, [])
            } catch {
                return (
                    [],
                    [
                        .init(
                            severity: .error,
                            message: "invalid owner-share configuration: \(error.localizedDescription)"
                        )
                    ]
                )
            }
        }

        guard let totalAmount,
              totalAmount > 0
        else {
            return ([], [])
        }

        return (
            [
                KIAAssetShare(
                    owner: nil,
                    ownerLabel: "unassigned",
                    percentage: 100,
                    amount: totalAmount
                )
            ],
            []
        )
    }

    private static func normalizedDisplayName(
        key: EntityKey,
        entity: EntityDef
    ) -> String {
        if let name = cleaned(entity.displayName) {
            return name
        }

        return key.identifier(displaying: .fullchain)
    }

    private static func normalizedDetails(
        from entity: EntityDef
    ) -> String? {
        guard let raw = cleaned(entity.metadata["details"]) else {
            return nil
        }

        return raw
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func ownerLabel(
        for ref: EntityRef
    ) -> String {
        if let cls = ref.class, let fam = ref.family {
            return [cls, fam, ref.alias.string].joined(separator: ".")
        }

        if let fam = ref.family {
            return [fam, ref.alias.string].joined(separator: ".")
        }

        if let cls = ref.class {
            return [cls, ref.alias.string].joined(separator: ".")
        }

        return ref.alias.string
    }

    @inline(__always)
    private static func category(
        entity: EntityDef
    ) -> AssetsOverviewCategory {
        AssetsOverviewCategory(
            metadataValue: cleaned(entity.metadata["asset_category"])
        )
    }

    @inline(__always)
    private static func rawAssetCategory(
        entity: EntityDef
    ) -> String? {
        cleaned(entity.metadata["asset_category"])
    }

    private static func typeLabel(
        key: EntityKey,
        entity: EntityDef
    ) -> String? {
        if let explicit = cleaned(entity.metadata["type"]) {
            return humanize(explicit)
        }

        let base = [key.class, key.family]
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return base.isEmpty ? nil : humanize(base)
    }

    @inline(__always)
    private static func hasRollforwardMetadata(
        entity: EntityDef
    ) -> Bool {
        entity.metadata.keys.contains { key in
            key.hasPrefix("dep.rollforward.")
        }
    }

    private static func hasPrivateUseSignal(
        key: EntityKey,
        entity: EntityDef
    ) -> Bool {
        let haystack = (
            [key.identifier(displaying: .fullchain), entity.displayName ?? ""]
            + entity.metadata.keys
            + entity.metadata.values
        )
        .joined(separator: " ")
        .lowercased()

        let needles = [
            "bijtelling",
            "prive",
            "privé",
            "privegebruik",
            "privégebruik",
            "private_use",
            "private use"
        ]

        return needles.contains { haystack.contains($0) }
    }

    private static func hasPlaceholderIdentity(
        key: EntityKey,
        entity: EntityDef
    ) -> Bool {
        let haystack = (
            [key.identifier(displaying: .fullchain), entity.displayName ?? ""]
            + entity.metadata.values
        )
        .joined(separator: " ")
        .lowercased()

        return haystack.contains("placeholder")
    }

    @inline(__always)
    private static func contains(
        _ date: Date,
        in window: PeriodWindow
    ) -> Bool {
        if let from = window.from, date < from {
            return false
        }

        if let to = window.to, date > to {
            return false
        }

        return true
    }

    @inline(__always)
    private static func cleaned(
        _ value: String?
    ) -> String? {
        guard let value else {
            return nil
        }

        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return trimmed.isEmpty ? nil : trimmed
    }

    private static func humanize(
        _ value: String
    ) -> String {
        value
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { part in
                part.lowercased().capitalized
            }
            .joined(separator: " ")
    }

    private static func sortRows(
        lhs: AssetsOverviewRow,
        rhs: AssetsOverviewRow
    ) -> Bool {
        if lhs.category.section.sortOrder != rhs.category.section.sortOrder {
            return lhs.category.section.sortOrder < rhs.category.section.sortOrder
        }

        if lhs.category.sortOrder != rhs.category.sortOrder {
            return lhs.category.sortOrder < rhs.category.sortOrder
        }

        let lineOrder = lhs.category.lineLabel.localizedCaseInsensitiveCompare(
            rhs.category.lineLabel
        )
        if lineOrder != ComparisonResult.orderedSame {
            return lineOrder == .orderedAscending
        }

        let nameOrder = lhs.displayName.localizedCaseInsensitiveCompare(
            rhs.displayName
        )
        if nameOrder != ComparisonResult.orderedSame {
            return nameOrder == .orderedAscending
        }

        return lhs.entityKey.identifier(displaying: .fullchain)
            < rhs.entityKey.identifier(displaying: .fullchain)
    }

    private static func uniqueIssues(
        _ values: [AssetsOverviewIssue]
    ) -> [AssetsOverviewIssue] {
        var seen = Set<AssetsOverviewIssue>()
        var result: [AssetsOverviewIssue] = []

        for value in values {
            if seen.insert(value).inserted {
                result.append(value)
            }
        }

        return result
    }
}
