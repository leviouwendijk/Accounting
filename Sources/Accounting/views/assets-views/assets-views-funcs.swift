import Foundation

public struct AssetViews {
    @inline(__always)
    public static func shouldExclude(
        entity: EntityDef
    ) -> Bool {
        guard let raw = cleaned(entity.metadata["asset_overview"])?.lowercased() else {
            return false
        }

        return raw == "exclude"
    }

    @inline(__always)
    public static func isAssetCandidate(
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

    public static func purchaseEntryValue(
        entity: EntityDef
    ) -> String? {
        cleaned(entity.metadata["purchase_entry"])
            ?? cleaned(entity.metadata["purchase_entry_id"])
            ?? cleaned(entity.metadata["legacy_journal_entry_id"])
    }

    public static func resolveShares(
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
            guard let totalAmount, totalAmount > 0 else {
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

        guard let totalAmount, totalAmount > 0 else {
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

    public static func normalizedDisplayName(
        key: EntityKey,
        entity: EntityDef
    ) -> String {
        if let name = cleaned(entity.displayName) {
            return name
        }

        return key.identifier(displaying: .fullchain)
    }

    public static func normalizedDetails(
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

    public static func ownerLabel(
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
    public static func category(
        entity: EntityDef
    ) -> AssetsOverviewCategory {
        AssetsOverviewCategory(
            metadataValue: cleaned(entity.metadata["asset_category"])
        )
    }

    @inline(__always)
    public static func rawAssetCategory(
        entity: EntityDef
    ) -> String? {
        cleaned(entity.metadata["asset_category"])
    }

    public static func typeLabel(
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
    public static func contains(
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
    public static func cleaned(
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

    public static func humanize(
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
}
