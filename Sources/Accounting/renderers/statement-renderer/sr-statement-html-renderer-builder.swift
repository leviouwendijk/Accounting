import Foundation

extension StatementHTMLRenderer {
    static func buildDocumentModel(
        bundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String,
        options: Options
    ) throws -> DocumentModel {
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
            options: options
        )

        var balances: [TableSection] = []

        if let assets = buildBalanceSection(
            title: "Balans: Activa",
            source: balanceSections.assets
        ) {
            balances.append(assets)
        }

        if let equity = buildBalanceSection(
            title: "Balans: Eigen Vermogen",
            source: balanceSections.equity
        ) {
            balances.append(equity)
        }

        if let liabilities = buildBalanceSection(
            title: "Balans: Passiva",
            source: balanceSections.liabilities
        ) {
            balances.append(liabilities)
        }

        if options.includeOtherBucket,
           let other = buildBalanceSection(
                title: "Balance Sheet — Other",
                source: balanceSections.other
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

        return DocumentModel(
            income: income,
            balances: balances,
            summary: summary
        )
    }

    static func buildIncomeSection(
        from lines: [StatementLine],
        options: Options
    ) -> TableSection {
        let rows = lines
            .filter { line in
                options.minAbsIncome == 0
                    ? true
                    : absDec(line.amount) >= options.minAbsIncome
            }
            .map { line in
                let base = options.omitIncomeLevel1Root ? 2 : 1

                return TableRow(
                    indent: max(0, line.level - base),
                    label: line.label,
                    amount: line.amount,
                    isTotal: false
                )
            }

        return TableSection(
            title: "Winst- en Verliesrekening",
            rows: rows
        )
    }

    static func buildBalanceSection(
        title: String,
        source: RGSBalanceBucketsOutput.Section?
    ) -> TableSection? {
        guard let source else {
            return nil
        }

        let rows = source.lines.map { line in
            TableRow(
                indent: line.relativeIndent,
                label: line.label,
                amount: line.amount,
                isTotal: false
            )
        }

        return TableSection(
            title: title,
            rows: rows,
            subtotal: source.subtotal
        )
    }
}
