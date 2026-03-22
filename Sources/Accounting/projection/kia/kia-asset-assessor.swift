import Foundation

public enum KIAAssetAssessor {
    public static func assess(
        entities: EntityStore,
        taxYear: Int,
        config: KIAConfig,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> (qualified: [KIAQualifiedAsset], excluded: [KIAExcludedAsset]) {
        var qualified: [KIAQualifiedAsset] = []
        var excluded: [KIAExcludedAsset] = []

        for (key, def) in entities.pairs() {
            guard shouldInspectForKIA(key: key, entity: def) else {
                continue
            }

            guard let depreciation = def.depreciation else {
                excluded.append(
                    .init(entityKey: key, reason: .missingDepreciation)
                )
                continue
            }

            let acquisitionDate = depreciation.schedule.effectiveDate
            let year = calendar.component(.year, from: acquisitionDate)

            guard year == taxYear else {
                excluded.append(
                    .init(entityKey: key, reason: .outsideTaxYear)
                )
                continue
            }

            let totalAmount = depreciation.acquistion.cost
            guard totalAmount > 0 else {
                excluded.append(
                    .init(entityKey: key, reason: .missingAcquisitionCost)
                )
                continue
            }

            guard totalAmount >= config.minimumAssetAmount else {
                excluded.append(
                    .init(
                        entityKey: key,
                        reason: .belowMinimumAssetAmount(totalAmount)
                    )
                )
                continue
            }

            let shares: [KIAAssetShare]
            do {
                shares = try resolveShares(
                    entity: def,
                    totalAmount: totalAmount
                )
            } catch {
                excluded.append(
                    .init(
                        entityKey: key,
                        reason: .invalidShareConfiguration(error.localizedDescription)
                    )
                )
                continue
            }

            let displayName = normalizedDisplayName(
                key: key,
                entity: def
            )

            qualified.append(
                KIAQualifiedAsset(
                    entityKey: key,
                    displayName: displayName,
                    acquisitionDate: acquisitionDate,
                    totalAmount: totalAmount,
                    shares: shares
                )
            )
        }

        qualified.sort { lhs, rhs in
            if lhs.acquisitionDate == rhs.acquisitionDate {
                return lhs.displayName < rhs.displayName
            }
            return lhs.acquisitionDate < rhs.acquisitionDate
        }

        return (qualified, excluded)
    }

    @inline(__always)
    private static func shouldInspectForKIA(
        key: EntityKey,
        entity: EntityDef
    ) -> Bool {
        if entity.depreciation != nil {
            return true
        }

        if key.identifier(displaying: .fullchain).contains("objects") {
            return true
        }

        return false
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
