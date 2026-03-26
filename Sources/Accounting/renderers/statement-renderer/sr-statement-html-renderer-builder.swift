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

    static func buildIncomeSection(
        from lines: [StatementLine],
        maps: RGSAssemblerResult,
        options: Options
    ) -> TableSection {
        let filtered = lines.filter { line in
            options.minAbsIncome == 0
                ? true
                : absDec(line.amount) >= options.minAbsIncome
        }

        let ids = filtered.map(\.id)

        let hierarchy = RenderedRowHierarchyBuilder.makeMap(
            idsInOrder: ids,
            parentById: maps.parentById
        )

        let rows = filtered.map { line in
            let h = hierarchy[line.id]
            let depth = h?.depth ?? 0

            let prefix = hierarchyPrefix(
                depth: depth,
                hasNextSibling: h?.hasNextSibling ?? false,
                ancestorHasNextSiblings: h?.ancestorHasNextSiblings ?? [],
                options: options
            )

            return TableRow(
                id: line.id,
                parentId: h?.parentId,
                depth: depth,
                prefix: prefix,
                label: line.label,
                amount: line.amount,
                direction: line.direction,
                orientation: line.orientation,
                isTotal: false
            )
        }

        return TableSection(
            kind: .incomeStatement,
            title: "Winst- en Verliesrekening",
            rows: rows
        )
    }

    static func buildBalanceSection(
        kind: BalanceSectionKind,
        title: String,
        source: RGSBalanceBucketsOutput.Section?,
        maps: RGSAssemblerResult,
        options: Options
    ) -> TableSection? {
        guard let source else {
            return nil
        }

        let ids = source.lines.map(\.id)

        let hierarchy = RenderedRowHierarchyBuilder.makeMap(
            idsInOrder: ids,
            parentById: maps.parentById
        )

        let rows = source.lines.map { line in
            let h = hierarchy[line.id]
            let depth = h?.depth ?? 0

            let prefix = hierarchyPrefix(
                depth: depth,
                hasNextSibling: h?.hasNextSibling ?? false,
                ancestorHasNextSiblings: h?.ancestorHasNextSiblings ?? [],
                options: options
            )

            return TableRow(
                id: line.id,
                parentId: h?.parentId,
                depth: depth,
                prefix: prefix,
                label: line.label,
                amount: line.amount,
                direction: line.direction,
                orientation: line.orientation,
                isTotal: false
            )
        }

        return TableSection(
            kind: .balance(kind),
            title: title,
            rows: rows,
            subtotal: source.subtotal
        )
    }

    // static func buildIncomeSection(
    //     from lines: [StatementLine],
    //     maps: RGSAssemblerResult,
    //     options: Options
    // ) -> TableSection {
    //     let filtered = lines.filter { line in
    //         options.minAbsIncome == 0
    //             ? true
    //             : absDec(line.amount) >= options.minAbsIncome
    //     }

    //     let ids = filtered.map(\.id)
    //     let fallbackBase = options.omitIncomeLevel1Root ? 2 : 1

    //     let rawDepthById: [Int: Int] = Dictionary(
    //         uniqueKeysWithValues: filtered.map { line in
    //             (line.id, max(0, line.level - fallbackBase))
    //         }
    //     )

    //     let distinctDepths = Array(Set(rawDepthById.values)).sorted()
    //     let compactDepthIndex = Dictionary(
    //         uniqueKeysWithValues: distinctDepths.enumerated().map { offset, depth in
    //             (depth, offset)
    //         }
    //     )

    //     let presentationDepthById: [Int: Int] = Dictionary(
    //         uniqueKeysWithValues: rawDepthById.map { id, rawDepth in
    //             (id, compactDepthIndex[rawDepth] ?? 0)
    //         }
    //     )

    //     let hierarchy = makePresentationHierarchyMap(
    //         idsInOrder: ids,
    //         canonicalParentById: maps.parentById,
    //         presentationDepthById: presentationDepthById
    //     )

    //     let rows = filtered.map { line in
    //         let h = hierarchy[line.id]
    //         let depth = h?.depth ?? presentationDepthById[line.id] ?? 0

    //         let prefix = hierarchyPrefix(
    //             depth: depth,
    //             hasNextSibling: h?.hasNextSibling ?? false,
    //             ancestorHasNextSiblings: h?.ancestorHasNextSiblings ?? [],
    //             options: options
    //         )

    //         return TableRow(
    //             id: line.id,
    //             parentId: h?.parentId,
    //             depth: depth,
    //             prefix: prefix,
    //             label: line.label,
    //             amount: line.amount,
    //             direction: line.direction,
    //             orientation: line.orientation,
    //             isTotal: false
    //         )
    //     }

    //     return TableSection(
    //         kind: .incomeStatement,
    //         title: "Winst- en Verliesrekening",
    //         rows: rows
    //     )
    // }

    // static func buildBalanceSection(
    //     kind: BalanceSectionKind,
    //     title: String,
    //     source: RGSBalanceBucketsOutput.Section?,
    //     maps: RGSAssemblerResult,
    //     options: Options
    // ) -> TableSection? {
    //     guard let source else {
    //         return nil
    //     }

    //     let ids = source.lines.map(\.id)

    //     let rawDepthById: [Int: Int] = Dictionary(
    //         uniqueKeysWithValues: source.lines.map { line in
    //             (line.id, max(0, line.relativeIndent))
    //         }
    //     )

    //     let distinctDepths = Array(Set(rawDepthById.values)).sorted()
    //     let compactDepthIndex: [Int: Int] = Dictionary(
    //         uniqueKeysWithValues: distinctDepths.enumerated().map { offset, depth in
    //             (depth, offset)
    //         }
    //     )

    //     let presentationDepthById: [Int: Int] = Dictionary(
    //         uniqueKeysWithValues: rawDepthById.map { id, rawDepth in
    //             (id, compactDepthIndex[rawDepth] ?? 0)
    //         }
    //     )

    //     let hierarchy = makePresentationHierarchyMap(
    //         idsInOrder: ids,
    //         canonicalParentById: maps.parentById,
    //         presentationDepthById: presentationDepthById
    //     )

    //     let rows = source.lines.map { line in
    //         let h = hierarchy[line.id]
    //         let depth = h?.depth ?? presentationDepthById[line.id] ?? 0

    //         let prefix = hierarchyPrefix(
    //             depth: depth,
    //             hasNextSibling: h?.hasNextSibling ?? false,
    //             ancestorHasNextSiblings: h?.ancestorHasNextSiblings ?? [],
    //             options: options
    //         )

    //         return TableRow(
    //             id: line.id,
    //             parentId: h?.parentId,
    //             depth: depth,
    //             prefix: prefix,
    //             label: line.label,
    //             amount: line.amount,
    //             direction: line.direction,
    //             orientation: line.orientation,
    //             isTotal: false
    //         )
    //     }

    //     return TableSection(
    //         kind: .balance(kind),
    //         title: title,
    //         rows: rows,
    //         subtotal: source.subtotal
    //     )
    // }
    
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
