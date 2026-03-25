import Foundation

extension AssetViews {
    public enum AssetValidationBuilder {
        public static func build(
            result: EntryCompileDriver.Result,
            tolerance: Decimal = 0
        ) throws -> AssetValidationReport {
            let entities = try DepreciationResolutionPass.run(
                on: result.entities,
                using: result.accounts
            )

            var rows: [AssetValidationRow] = []
            var diagnosticsCounts: [String: Int] = [:]

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
                let acquisitionEntry = profileAccess?.acquisitionEntry
                let acquisitionAccount = profileAccess?.acquisitionAccount
                let acquisitionCost = profileAccess?.acquisition.cost

                var issues: [AssetAcquisitionValidationIssue] = []

                if acquisitionDate == nil {
                    issues.append(
                        .init(
                            severity: .warning,
                            message: "missing acquisition date"
                        )
                    )
                }

                if acquisitionEntry == nil {
                    issues.append(
                        .init(
                            severity: .warning,
                            message: "missing acquisition entry"
                        )
                    )
                }

                if acquisitionAccount == nil {
                    issues.append(
                        .init(
                            severity: .warning,
                            message: "missing acquisition account"
                        )
                    )
                }

                if acquisitionCost == nil {
                    issues.append(
                        .init(
                            severity: .warning,
                            message: "missing acquisition valuation"
                        )
                    )
                }

                let matches = collectLedgerMatches(
                    resolved: result.resolved,
                    entryId: acquisitionEntry,
                    entityKey: key,
                    account: acquisitionAccount
                )

                let matchedAmount = matches.reduce(Decimal.zero) { partial, match in
                    partial + match.amount.magnitude
                }

                if let acquisitionEntry, matches.isEmpty {
                    issues.append(
                        .init(
                            severity: .error,
                            message: "referenced acquisition entry \(acquisitionEntry) contains no matching lines for this asset/account"
                        )
                    )
                }

                if let expected = acquisitionCost {
                    let delta = matchedAmount - expected
                    let magnitude = delta.magnitude

                    if magnitude > tolerance {
                        issues.append(
                            .init(
                                severity: .error,
                                message: "ledger acquisition amount \(fmt(matchedAmount)) does not match profile valuation \(fmt(expected))"
                            )
                        )
                    }
                }

                issues = uniqueIssues(issues)

                for issue in issues {
                    diagnosticsCounts[issue.message, default: 0] += 1
                }

                rows.append(
                    .init(
                        entityKey: key,
                        displayName: displayName,
                        details: details,
                        acquisitionDate: acquisitionDate,
                        commissionDate: commissionDate,
                        acquisitionEntry: acquisitionEntry,
                        acquisitionAccount: acquisitionAccount,
                        acquisitionCost: acquisitionCost,
                        matchedLedgerAmount: matchedAmount,
                        ledgerMatches: matches,
                        issues: issues
                    )
                )
            }

            rows.sort { lhs, rhs in
                lhs.displayName.localizedCaseInsensitiveCompare(
                    rhs.displayName
                ) == .orderedAscending
            }

            return .init(
                rows: rows,
                diagnosticsCounts: diagnosticsCounts
            )
        }

        private static func collectLedgerMatches(
            resolved: [ResolvedEntry],
            entryId: Int?,
            entityKey: EntityKey,
            account: AccountRef?
        ) -> [AssetAcquisitionLedgerMatch] {
            guard let entryId else {
                return []
            }

            let targetAccount = account.map(accountKeyString)

            var out: [AssetAcquisitionLedgerMatch] = []

            for entry in resolved {
                guard entry.id == entryId else {
                    continue
                }

                for line in entry.lines {
                    guard line.entity == entityKey else {
                        continue
                    }

                    if let targetAccount {
                        let candidate = accountKeyString(line.account)
                        guard candidate == targetAccount else {
                            continue
                        }
                    }

                    guard case let .absolute(date) = entry.date else {
                        continue
                    }

                    out.append(
                        .init(
                            entryId: entry.id,
                            date: date,
                            amount: line.amount,
                            direction: line.direction
                        )
                    )
                }
            }

            return out
        }

        private static func accountKeyString(
            _ value: AccountRef
        ) -> String {
            switch value {
            case .identifier(let value):
                return value

            case .code(let value):
                return value

            case .path(let segments):
                return segments.joined(separator: ".")
            }
        }

        private static func accountKeyString(
            _ value: AccountKey
        ) -> String {
            value.code
        }

        private static func uniqueIssues(
            _ issues: [AssetAcquisitionValidationIssue]
        ) -> [AssetAcquisitionValidationIssue] {
            var seen = Set<String>()
            var out: [AssetAcquisitionValidationIssue] = []

            for issue in issues {
                let key = "\(issue.severity.rawValue)|\(issue.message)"
                if seen.insert(key).inserted {
                    out.append(issue)
                }
            }

            return out
        }

        private static func fmt(
            _ value: Decimal,
            digits: Int = 2
        ) -> String {
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "nl_NL")
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = digits
            formatter.maximumFractionDigits = digits

            return formatter.string(from: value as NSDecimalNumber)
                ?? value.description
        }
    }
}
