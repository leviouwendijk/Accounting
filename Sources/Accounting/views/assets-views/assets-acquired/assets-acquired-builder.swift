import Foundation

extension AssetViews {
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
                if AssetViews.shouldExclude(entity: entity) {
                    continue
                }

                guard AssetViews.isAssetCandidate(
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

                let displayName = AssetViews.normalizedDisplayName(
                    key: key,
                    entity: entity
                )

                let details = AssetViews.normalizedDetails(
                    from: entity
                )

                let acquisitionDate = profileAccess?.acquisitionDate
                let commissionDate = profileAccess?.commissionDate
                let acquisitionCost = profileAccess?.acquisition.cost

                let category = AssetViews.category(
                    entity: entity
                )

                let type = AssetViews.typeLabel(
                    key: key,
                    entity: entity
                )

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

                guard AssetViews.contains(
                    purchaseDate,
                    in: period
                ) else {
                    continue
                }

                let (ownerShares, shareIssues) = AssetViews.resolveShares(
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
}
