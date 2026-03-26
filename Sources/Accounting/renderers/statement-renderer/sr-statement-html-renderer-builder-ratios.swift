import Foundation

extension StatementHTMLRenderer {
    static func buildRatiosSection(
        from ratios: FinancialRatios?
    ) -> RatiosSection? {
        guard let ratios else {
            return nil
        }

        return RatiosSection(
            title: "Financiële ratio’s",
            rows: [
                RatioRow(
                    label: "Solvabiliteit",
                    description: "Aandeel van de activa dat met eigen vermogen is gefinancierd.",
                    formula: "Eigen vermogen / Activa",
                    value: ratios.equityRatio,
                    style: .percentage
                ),
                RatioRow(
                    label: "Schuldratio",
                    description: "Aandeel van de activa dat met schulden is gefinancierd.",
                    formula: "Schulden / Activa",
                    value: ratios.debtRatio,
                    style: .percentage
                ),
                RatioRow(
                    label: "Debt / Equity",
                    description: "Verhouding tussen vreemd vermogen en eigen vermogen.",
                    formula: "Schulden / Eigen vermogen",
                    value: ratios.debtToEquity,
                    style: .multiple
                ),
                RatioRow(
                    label: "Current ratio",
                    description: "Mate waarin kortlopende schulden door vlottende activa worden gedekt.",
                    formula: "Vlottende activa / Kortlopende schulden",
                    value: ratios.currentRatio,
                    style: .multiple
                ),
                RatioRow(
                    label: "Quick ratio",
                    description: "Strengere liquiditeitsmaat zonder voorraad en OHW.",
                    formula: "(Vlottende activa - voorraad - OHW) / Kortlopende schulden",
                    value: ratios.quickRatio,
                    style: .multiple
                ),
                RatioRow(
                    label: "Gross margin",
                    description: "Brutowinst als aandeel van de netto-omzet.",
                    formula: "Brutowinst / Netto-omzet",
                    value: ratios.grossMargin,
                    style: .percentage
                ),
                RatioRow(
                    label: "Operating margin",
                    description: "Operationeel resultaat als aandeel van de netto-omzet.",
                    formula: "Operationeel resultaat / Netto-omzet",
                    value: ratios.operatingMargin,
                    style: .percentage
                ),
                RatioRow(
                    label: "Net margin",
                    description: "Nettowinst als aandeel van de netto-omzet.",
                    formula: "Nettowinst / Netto-omzet",
                    value: ratios.netMargin,
                    style: .percentage
                ),
                RatioRow(
                    label: "Equity multiplier",
                    description: "Mate van financiële hefboom op basis van activa versus eigen vermogen.",
                    formula: "Activa / Eigen vermogen",
                    value: ratios.equityMultiplier,
                    style: .multiple
                ),
                RatioRow(
                    label: "ROA",
                    description: "Rendement op het totaal aan ingezette activa.",
                    formula: "Nettowinst / Activa",
                    value: ratios.returnOnAssets,
                    style: .percentage
                ),
                RatioRow(
                    label: "ROE",
                    description: "Rendement op het eigen vermogen.",
                    formula: "Nettowinst / Eigen vermogen",
                    value: ratios.returnOnEquity,
                    style: .percentage
                )
            ]
        )
    }
}
