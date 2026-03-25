import Foundation

public enum AcquiredAssetsBuilder {
    public static func build(
        result: EntryCompileDriver.Result,
        period: PeriodWindow,
        anchor: Date,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) throws -> AcquiredAssetsReport {
        let entities = try DepreciationResolutionPass.run(
            on: result.entities,
            using: result.accounts
        )

        // var calendar = calendar

        var rows: [AcquiredAssetRow] = []
        var diagnosticCounts: [String: Int] = [:]
        var skippedMissingDateCount = 0

        for (key, entity) in entities.pairs() {
            if shouldExclude(entity: entity) {
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
            let commissionDate = profileAccess?.commissionDate
            let acquisitionCost = profileAccess?.acquisition.cost

            let category = AssetsOverviewCategory(
                metadataValue: cleaned(entity.metadata["asset_category"])
            )

            let type = typeLabel(
                key: key,
                entity: entity
            )

            // let purchaseEntry = purchaseEntryValue(
            //     entity: entity
            // )
            let acquisitionEntry = profileAccess?.acquisitionEntry
            let acquisitionAccount = profileAccess?.acquisitionAccount

            let purchaseDateInfo: (Date, AcquiredAssetPurchaseDateSource)? = {
                if let acquisitionDate {
                    return (acquisitionDate, .acquisitionDate)
                }

                if let commissionDate {
                    return (commissionDate, .commissionDateFallback)
                }

                return nil
            }()

            guard let (purchaseDate, purchaseDateSource) = purchaseDateInfo else {
                skippedMissingDateCount += 1
                diagnosticCounts["missing acquisition/commission date", default: 0] += 1
                continue
            }

            guard within(purchaseDate, window: period) else {
                continue
            }

            let (ownerShares, shareIssues) = resolveShares(
                entity: entity,
                totalAmount: acquisitionCost
            )

            var issues: [AssetsOverviewIssue] = []
            issues.append(contentsOf: shareIssues)

            if acquisitionDate == nil {
                issues.append(
                    .init(
                        severity: .warning,
                        message: "missing acquisition date; using commission date"
                    )
                )
            }

            if acquisitionCost == nil || acquisitionCost == 0 {
                issues.append(
                    .init(
                        severity: .warning,
                        message: "missing acquisition cost"
                    )
                )
            }

            if acquisitionEntry == nil {
                issues.append(
                    .init(
                        severity: .info,
                        message: "missing acquisition entry"
                    )
                )
            }

            if acquisitionAccount == nil {
                issues.append(
                    .init(
                        severity: .info,
                        message: "missing acquisition account"
                    )
                )
            }

            issues = uniqueIssues(issues)

            let row = AcquiredAssetRow(
                entityKey: key,
                displayName: displayName,
                details: details,
                category: category,
                type: type,
                purchaseDate: purchaseDate,
                purchaseDateSource: purchaseDateSource,
                acquisitionDate: acquisitionDate,
                commissionDate: commissionDate,
                acquisitionCost: acquisitionCost,
                acquisitionEntry: acquisitionEntry,
                acquisitionAccount: acquisitionAccount,
                ownerShares: ownerShares,
                issues: issues
            )

            rows.append(row)

            for issue in issues {
                diagnosticCounts[issue.message, default: 0] += 1
            }
        }

        rows.sort(by: sortRows)

        let totalAcquisitionCost = rows.reduce(Decimal(0)) { partial, row in
            partial + (row.acquisitionCost ?? 0)
        }

        return AcquiredAssetsReport(
            period: period,
            anchor: anchor,
            rows: rows,
            skippedMissingDateCount: skippedMissingDateCount,
            totalAcquisitionCost: totalAcquisitionCost,
            diagnosticCounts: diagnosticCounts
        )
    }

    @inline(__always)
    private static func shouldExclude(
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

    private static func purchaseEntryValue(
        entity: EntityDef
    ) -> String? {
        cleaned(entity.metadata["purchase_entry"])
            ?? cleaned(entity.metadata["purchase_entry_id"])
            ?? cleaned(entity.metadata["legacy_journal_entry_id"])
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
    private static func within(
        _ date: Date,
        window: PeriodWindow
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
        lhs: AcquiredAssetRow,
        rhs: AcquiredAssetRow
    ) -> Bool {
        if lhs.purchaseDate != rhs.purchaseDate {
            return lhs.purchaseDate < rhs.purchaseDate
        }

        let nameOrder = lhs.displayName.localizedCaseInsensitiveCompare(
            rhs.displayName
        )
        if nameOrder != .orderedSame {
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
