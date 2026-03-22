import Foundation

public enum KIAAssetAssessor {
    public static func assess(
        entities: EntityStore,
        taxYear: Int,
        config: KIAConfig,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> KIAAssessmentResult {
        var qualified: [KIAQualifiedAsset] = []
        var excluded: [KIAExcludedAsset] = []
        var diagnostics: [KIADiagnosticRecord] = []

        for (key, def) in entities.pairs() {
            let displayName = normalizedDisplayName(
                key: key,
                entity: def
            )

            let wasCandidate = isAssetCandidate(
                key: key,
                entity: def
            )

            guard wasCandidate else {
                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: false,
                        commissionDate: nil,
                        acquisitionCost: nil,
                        shareSummary: nil,
                        outcome: .excluded(.notAssetCandidate)
                    )
                )
                continue
            }

            let profile = def.profile
            let depreciation = def.depreciation

            let commissionDate = extractCommissionDate(
                entity: def
            )
            let acquisitionCost = extractAcquisitionCost(
                entity: def
            )

            guard profile != nil || depreciation != nil else {
                let reason: KIAQualificationReason = .missingProfile

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: commissionDate,
                        acquisitionCost: acquisitionCost,
                        shareSummary: nil,
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            guard let commissionDate else {
                let reason: KIAQualificationReason = .missingCommissionDate

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: nil,
                        acquisitionCost: acquisitionCost,
                        shareSummary: nil,
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            let actualYear = calendar.component(.year, from: commissionDate)
            guard actualYear == taxYear else {
                let reason: KIAQualificationReason = .outsideTaxYear(
                    actualYear: actualYear
                )

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: commissionDate,
                        acquisitionCost: acquisitionCost,
                        shareSummary: nil,
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            guard let acquisitionCost, acquisitionCost > 0 else {
                let reason: KIAQualificationReason = .missingAcquisitionCost

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: commissionDate,
                        acquisitionCost: acquisitionCost,
                        shareSummary: nil,
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            guard acquisitionCost >= config.minimumAssetAmount else {
                let reason: KIAQualificationReason = .belowMinimumAssetAmount(
                    acquisitionCost
                )

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: commissionDate,
                        acquisitionCost: acquisitionCost,
                        shareSummary: nil,
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            let shares: [KIAAssetShare]
            do {
                shares = try resolveShares(
                    entity: def,
                    totalAmount: acquisitionCost
                )
            } catch {
                let reason: KIAQualificationReason = .invalidShareConfiguration(
                    error.localizedDescription
                )

                excluded.append(
                    .init(entityKey: key, reason: reason)
                )

                diagnostics.append(
                    KIADiagnosticRecord(
                        entityKey: key,
                        displayName: displayName,
                        wasCandidate: true,
                        commissionDate: commissionDate,
                        acquisitionCost: acquisitionCost,
                        shareSummary: "error: \(error.localizedDescription)",
                        outcome: .excluded(reason)
                    )
                )
                continue
            }

            let asset = KIAQualifiedAsset(
                entityKey: key,
                displayName: displayName,
                acquisitionDate: commissionDate,
                totalAmount: acquisitionCost,
                shares: shares
            )

            qualified.append(asset)

            diagnostics.append(
                KIADiagnosticRecord(
                    entityKey: key,
                    displayName: displayName,
                    wasCandidate: true,
                    commissionDate: commissionDate,
                    acquisitionCost: acquisitionCost,
                    shareSummary: shareSummary(from: shares),
                    outcome: .qualified
                )
            )
        }

        qualified.sort { lhs, rhs in
            if lhs.acquisitionDate == rhs.acquisitionDate {
                return lhs.displayName < rhs.displayName
            }
            return lhs.acquisitionDate < rhs.acquisitionDate
        }

        diagnostics.sort { lhs, rhs in
            lhs.entityKey.identifier(displaying: .fullchain)
                < rhs.entityKey.identifier(displaying: .fullchain)
        }

        return KIAAssessmentResult(
            qualified: qualified,
            excluded: excluded,
            diagnostics: diagnostics
        )
    }

    @inline(__always)
    private static func isAssetCandidate(
        key: EntityKey,
        entity: EntityDef
    ) -> Bool {
        if key.class == "objects" {
            return true
        }

        if entity.profile != nil {
            return true
        }

        if entity.depreciation != nil {
            return true
        }

        if entity.depreciationDraft != nil {
            return true
        }

        if let type = entity.metadata["type"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           type == "tangible"
        {
            return true
        }

        return false
    }

    @inline(__always)
    private static func extractCommissionDate(
        entity: EntityDef
    ) -> Date? {
        if let date = entity.profile?.commissionDate {
            return date
        }

        if let date = entity.profile?.acquisitionDate {
            return date
        }

        if let depreciation = entity.depreciation {
            return depreciation.schedule.effectiveDate
        }

        return nil
    }

    @inline(__always)
    private static func extractAcquisitionCost(
        entity: EntityDef
    ) -> Decimal? {
        if let cost = entity.profile?.acquisitionCost?.cost, cost > 0 {
            return cost
        }

        if let depreciation = entity.depreciation {
            let cost = depreciation.acquistion.cost
            if cost > 0 {
                return cost
            }
        }

        return nil
    }

    private static func resolveShares(
        entity: EntityDef,
        totalAmount: Decimal
    ) throws -> [KIAAssetShare] {
        if let kia = entity.kia {
            return kia.shares.map { share in
                KIAAssetShare(
                    owner: share.owner,
                    ownerLabel: ownerLabel(for: share.owner),
                    percentage: share.percentage,
                    amount: share.amount
                )
            }
        }

        if let kiaDraft = entity.kiaDraft {
            let resolved = try kiaDraft.resolve(acquisitionCost: totalAmount)
            return resolved.shares.map { share in
                KIAAssetShare(
                    owner: share.owner,
                    ownerLabel: ownerLabel(for: share.owner),
                    percentage: share.percentage,
                    amount: share.amount
                )
            }
        }

        return [
            KIAAssetShare(
                owner: nil,
                ownerLabel: "unassigned",
                percentage: 100,
                amount: totalAmount
            )
        ]
    }

    private static func shareSummary(
        from shares: [KIAAssetShare]
    ) -> String {
        if shares.isEmpty {
            return "none"
        }

        return shares.map { share in
            "\(share.ownerLabel): \(share.percentage)% → \(share.amount)"
        }
        .joined(separator: "; ")
    }

    private static func normalizedDisplayName(
        key: EntityKey,
        entity: EntityDef
    ) -> String {
        if let name = entity.displayName, !name.isEmpty {
            return name
        }

        return key.identifier(displaying: .fullchain)
    }

    private static func ownerLabel(for ref: EntityRef) -> String {
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
}
