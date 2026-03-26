import Foundation

extension StatementHTMLRenderer {
    static func buildDocumentModel(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String,
        options: Options
    ) throws -> DocumentModel {
        let maps = try RGSAssembler.makeMaps(from: chart)

        let balanceSections = try RGSPrinter.computeBalanceByL2Sections(
            bundle: bundle,
            chart: chart,
            equityCode: equityCode,
            includeOtherBucket: options.includeOtherBucket
        )

        let incomeSections = try RGSPrinter.incomeSections(
            bundle: bundle,
            chart: chart,
            omitLevel1Root: options.omitIncomeLevel1Root
        )

        let income = buildIncomeSection(
            from: incomeSections.first?.lines ?? [],
            maps: maps,
            options: options
        )

        var balances: [TableSection] = []

        if let assets = buildBalanceSection(
            kind: .assets,
            title: "Balans: Activa",
            source: balanceSections.assets,
            maps: maps,
            options: options
        ) {
            balances.append(assets)
        }

        if let equity = buildBalanceSection(
            kind: .equity,
            title: "Balans: Eigen Vermogen",
            source: balanceSections.equity,
            maps: maps,
            options: options
        ) {
            balances.append(equity)
        }

        if let liabilities = buildBalanceSection(
            kind: .liabilities,
            title: "Balans: Passiva",
            source: balanceSections.liabilities,
            maps: maps,
            options: options
        ) {
            balances.append(liabilities)
        }

        if options.includeOtherBucket,
           let other = buildBalanceSection(
                kind: .other,
                title: "Balans: Overig",
                source: balanceSections.other,
                maps: maps,
                options: options
           ) {
            balances.append(other)
        }

        let summary = balanceSections.summary.map {
            BalanceSummary(
                assets: $0.assets,
                equity: $0.equity,
                liabilities: $0.liabilities
            )
        }

        let ratios = buildRatiosSection(
            from: bundle.analytics?.ratios
        )

        return DocumentModel(
            income: income,
            balances: balances,
            summary: summary,
            ratios: ratios
        )
    }
}
