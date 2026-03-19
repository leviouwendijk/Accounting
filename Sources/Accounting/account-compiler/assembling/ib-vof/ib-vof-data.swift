import Foundation

public extension RGSAssembler {
    static func ibVOFOverview(
        _ title: String = "IB VOF overview",
        bundle: StatementBundle,
        chart: CompiledChart,
        businessEntity: BusinessEntity = .vof,
        minAbs: Decimal = 0
    ) throws -> IBVOFOverview {
        let maps = try RGSAssembler.makeMaps(from: chart)
        let nodes = chart.nodes

        let idByCode: [String: Int] = Dictionary(
            uniqueKeysWithValues: nodes.map { ($0.codes.code, $0.id) }
        )

        let dirById = maps.directionById
        let totals = bundle.totalsById

        let analytics: BundleAnalytics
        if let existing = bundle.analytics {
            analytics = existing
        } else {
            analytics = try RGSAssembler.makeAnalytics(
                chart: chart,
                bundle: bundle,
                omslag: .apply
            )
        }

        @inline(__always)
        func absD(_ x: Decimal) -> Decimal {
            x < 0 ? -x : x
        }

        @inline(__always)
        func shownAmount(for code: String) -> Decimal? {
            guard let id = idByCode[code] else {
                return nil
            }

            let raw = totals[id] ?? 0
            let dir = dirById[id] ?? .debit
            let shown = RGSAssembler.present(
                raw,
                direction: dir,
                mode: .apply
            )

            if minAbs > 0, absD(shown) < minAbs {
                return nil
            }

            return shown
        }

        var resultRows: [IBVOFOverview.Row] = []

        let omzet = shownAmount(for: "WOmz")
        let kostprijs = shownAmount(for: "WKpr")
        let bedrijfskosten = shownAmount(for: "WBed")
        let afschrijvingen = shownAmount(for: "WAfs")
        let financieel = shownAmount(for: "WFbe")
        let winst = shownAmount(for: businessEntity.autoCloseTargets().netIncomeCode)

        if let omzet {
            resultRows.append(
                .init(
                    field: .netTurnover,
                    label: "Netto-omzet",
                    amount: omzet,
                    sourceCodes: ["WOmz"]
                )
            )
        }

        if let kostprijs {
            resultRows.append(
                .init(
                    field: .costOfRevenue,
                    label: "Kostprijs van de omzet",
                    amount: kostprijs,
                    sourceCodes: ["WKpr"]
                )
            )
        }

        if let omzet, let kostprijs {
            resultRows.append(
                .init(
                    field: .grossProfit,
                    label: "Brutowinst",
                    amount: omzet - kostprijs,
                    sourceCodes: ["WOmz", "WKpr"],
                    derived: true,
                    note: "Derived as netto-omzet minus kostprijs van de omzet."
                )
            )
        }

        if let bedrijfskosten {
            resultRows.append(
                .init(
                    field: .operatingExpenses,
                    label: "Overige bedrijfskosten",
                    amount: bedrijfskosten,
                    sourceCodes: ["WBed"]
                )
            )
        }

        if let afschrijvingen {
            resultRows.append(
                .init(
                    field: .depreciationExpenses,
                    label: "Afschrijvingen",
                    amount: afschrijvingen,
                    sourceCodes: ["WAfs"]
                )
            )
        }

        if let bedrijfskosten, let afschrijvingen {
            resultRows.append(
                .init(
                    field: .totalBusinessExpenses,
                    label: "Totale bedrijfskosten",
                    amount: bedrijfskosten + afschrijvingen,
                    sourceCodes: ["WBed", "WAfs"],
                    derived: true,
                    note: "Derived as overige bedrijfskosten plus afschrijvingen."
                )
            )
        }

        if let financieel {
            resultRows.append(
                .init(
                    field: .financialResult,
                    label: "Financiële baten en lasten",
                    amount: financieel,
                    sourceCodes: ["WFbe"]
                )
            )
        }

        if let winst {
            resultRows.append(
                .init(
                    field: .netProfit,
                    label: "Winstsaldo",
                    amount: winst,
                    sourceCodes: [businessEntity.autoCloseTargets().netIncomeCode],
                    note: "Taken from the configured auto-close net-income node for the business entity."
                )
            )
        }

        var capitalRows: [IBVOFOverview.Row] = []

        if let stortingen = shownAmount(for: "BEivKapPrsPsk") {
            capitalRows.append(
                .init(
                    field: .privateContributions,
                    label: "Privéstortingen",
                    amount: stortingen,
                    sourceCodes: ["BEivKapPrsPsk"]
                )
            )
        }

        if let onttrekkingen = shownAmount(for: "BEivKapProPok") {
            capitalRows.append(
                .init(
                    field: .privateWithdrawals,
                    label: "Privéonttrekkingen",
                    amount: onttrekkingen,
                    sourceCodes: ["BEivKapProPok"]
                )
            )
        }

        let balanceRows: [IBVOFOverview.Row] = [
            .init(
                field: .assets,
                label: "Activa",
                amount: analytics.l2Totals.assets,
                derived: true,
                note: "Taken from bundle analytics L2 totals."
            ),
            .init(
                field: .equity,
                label: "Eigen vermogen",
                amount: analytics.l2Totals.equity,
                derived: true,
                note: "Taken from bundle analytics L2 totals."
            ),
            .init(
                field: .liabilities,
                label: "Schulden",
                amount: analytics.l2Totals.liabilities,
                derived: true,
                note: "Taken from bundle analytics L2 totals."
            )
        ]

        var sections: [IBVOFOverview.Section] = []

        if !resultRows.isEmpty {
            sections.append(
                .init(
                    key: "result",
                    title: "Resultaat",
                    rows: resultRows
                )
            )
        }

        if !capitalRows.isEmpty {
            sections.append(
                .init(
                    key: "capital",
                    title: "Privé en kapitaal",
                    rows: capitalRows
                )
            )
        }

        sections.append(
            .init(
                key: "balance",
                title: "Balanssamenvatting",
                rows: balanceRows
            )
        )

        var summaries: [IBVOFOverview.Summary] = []

        if let winst {
            summaries.append(
                .init(
                    label: "Winstsaldo",
                    amount: winst
                )
            )
        }

        summaries.append(
            .init(
                label: "Balanscontrole (EV + schulden)",
                amount: analytics.l2Totals.equity + analytics.l2Totals.liabilities
            )
        )

        return .init(
            title: title,
            sections: sections,
            summaries: summaries
        )
    }
}
