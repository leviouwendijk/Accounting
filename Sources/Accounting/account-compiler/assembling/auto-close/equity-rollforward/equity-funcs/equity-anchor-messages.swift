extension OwnerEquity.Rollforward {
    public static func equityAnchorMessages(
        earliest: EquityPeriod,
        cfg: EquityRollforwardConfig,
        maps: ChartMaps
    ) -> [String] {
        let hasPostedBegin: Bool = {
            if let eb = earliest.bundle.entity?.byAccount,
               let code = cfg.entity.periodOpeningRouting.equityOpeningCode,
               let id = maps.idByCode[code] {
                return eb[id] != nil
            }
            return false
        }()

        let hasPerOwnerClosing = !equityClosingByOwner(
            bundle: earliest.bundle,
            cfg: cfg,
            maps: maps
        ).isEmpty

        if hasPostedBegin {
            return ["Earliest anchor: owner-tagged opening found — using posted per-owner BEGIN."]
        } else if hasPerOwnerClosing {
            return ["Earliest anchor: backsolved from per-owner closing − movements (no % guessing)."]
        } else {
            return ["Earliest anchor: none posted and no per-owner closing — BEGIN = 0 per owner."]
        }
    }
}
