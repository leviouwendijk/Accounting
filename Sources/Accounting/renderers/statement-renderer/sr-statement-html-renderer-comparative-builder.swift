import Foundation

extension StatementHTMLRenderer {
    struct ComparativeMergeSeed: Sendable {
        let id: Int
        let label: String
        let amount: Decimal
        let direction: Direction
        let orientation: AccountOrientation
    }

    public static func renderComparative(
        current: PeriodAssembleResultPeriod,
        previous: PeriodAssembleResultPeriod,
        chart: CompiledChart,
        equityCode: String = "BEiv",
        currentColumnTitle: String,
        previousColumnTitle: String,
        options: Options = .init()
    ) throws -> String {
        let comparativeModel = try buildComparativeDocumentModel(
            currentBundle: current.bundle,
            previousBundle: previous.bundle,
            chart: chart,
            equityCode: equityCode,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            options: options
        )

        return renderComparativeDocument(
            model: comparativeModel,
            options: options
        )
    }

    static func buildComparativeDocumentModel(
        currentBundle: StatementBundle,
        previousBundle: StatementBundle,
        chart: CompiledChart,
        equityCode: String,
        currentColumnTitle: String,
        previousColumnTitle: String,
        options: Options
    ) throws -> ComparativeDocumentModel {
        let maps = try RGSAssembler.makeMaps(from: chart)

        let currentBalanceSections = try RGSPrinter.computeBalanceByL2Sections(
            bundle: currentBundle,
            chart: chart,
            equityCode: equityCode,
            includeOtherBucket: options.includeOtherBucket
        )

        let previousBalanceSections = try RGSPrinter.computeBalanceByL2Sections(
            bundle: previousBundle,
            chart: chart,
            equityCode: equityCode,
            includeOtherBucket: options.includeOtherBucket
        )

        let currentIncomeSections = try RGSPrinter.incomeSections(
            bundle: currentBundle,
            chart: chart,
            omitLevel1Root: options.omitIncomeLevel1Root
        )

        let previousIncomeSections = try RGSPrinter.incomeSections(
            bundle: previousBundle,
            chart: chart,
            omitLevel1Root: options.omitIncomeLevel1Root
        )

        let income = buildComparativeIncomeSection(
            current: currentIncomeSections.first?.lines ?? [],
            previous: previousIncomeSections.first?.lines ?? [],
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            maps: maps,
            options: options
        )

        var balances: [ComparativeSection] = []

        if let assets = buildComparativeBalanceSection(
            kind: .assets,
            title: "Balans: Activa",
            current: currentBalanceSections.assets,
            previous: previousBalanceSections.assets,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            maps: maps,
            options: options
        ) {
            balances.append(assets)
        }

        if let equity = buildComparativeBalanceSection(
            kind: .equity,
            title: "Balans: Eigen Vermogen",
            current: currentBalanceSections.equity,
            previous: previousBalanceSections.equity,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            maps: maps,
            options: options
        ) {
            balances.append(equity)
        }

        if let liabilities = buildComparativeBalanceSection(
            kind: .liabilities,
            title: "Balans: Passiva",
            current: currentBalanceSections.liabilities,
            previous: previousBalanceSections.liabilities,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            maps: maps,
            options: options
        ) {
            balances.append(liabilities)
        }

        if options.includeOtherBucket,
           let other = buildComparativeBalanceSection(
                kind: .other,
                title: "Balans: Overig",
                current: currentBalanceSections.other,
                previous: previousBalanceSections.other,
                currentColumnTitle: currentColumnTitle,
                previousColumnTitle: previousColumnTitle,
                maps: maps,
                options: options
           ) {
            balances.append(other)
        }

        let currentSummary = currentBalanceSections.summary.map {
            BalanceSummary(
                assets: $0.assets,
                equity: $0.equity,
                liabilities: $0.liabilities
            )
        }

        let previousSummary = previousBalanceSections.summary.map {
            BalanceSummary(
                assets: $0.assets,
                equity: $0.equity,
                liabilities: $0.liabilities
            )
        }

        let currentRatios = buildRatiosSection(
            from: currentBundle.analytics?.ratios
        )

        let previousRatios = buildRatiosSection(
            from: previousBundle.analytics?.ratios
        )

        return ComparativeDocumentModel(
            income: income,
            balances: balances,
            summary: buildComparativeSummary(
                current: currentSummary,
                previous: previousSummary,
                currentColumnTitle: currentColumnTitle,
                previousColumnTitle: previousColumnTitle
            ),
            ratios: buildComparativeRatiosSection(
                current: currentRatios,
                previous: previousRatios,
                currentColumnTitle: currentColumnTitle,
                previousColumnTitle: previousColumnTitle
            )
        )
    }

    static func buildComparativeIncomeSection(
        current: [StatementLine],
        previous: [StatementLine],
        currentColumnTitle: String,
        previousColumnTitle: String,
        maps: RGSAssemblerResult,
        options: Options
    ) -> ComparativeSection {
        let currentRows = current
            .filter { line in
                options.minAbsIncome == 0
                    ? true
                    : DecimalFuncs.absDec(line.amount) >= options.minAbsIncome
            }
            .map {
                ComparativeMergeSeed(
                    id: $0.id,
                    label: $0.label,
                    amount: $0.amount,
                    direction: $0.direction,
                    orientation: $0.orientation
                )
            }

        let previousRows = previous
            .filter { line in
                options.minAbsIncome == 0
                    ? true
                    : DecimalFuncs.absDec(line.amount) >= options.minAbsIncome
            }
            .map {
                ComparativeMergeSeed(
                    id: $0.id,
                    label: $0.label,
                    amount: $0.amount,
                    direction: $0.direction,
                    orientation: $0.orientation
                )
            }

        return buildComparativeSection(
            kind: .incomeStatement,
            title: "Winst- en Verliesrekening",
            currentRows: currentRows,
            previousRows: previousRows,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            currentSubtotal: nil,
            previousSubtotal: nil,
            maps: maps,
            options: options
        )
    }

    static func buildComparativeBalanceSection(
        kind: BalanceSectionKind,
        title: String,
        current: RGSBalanceBucketsOutput.Section?,
        previous: RGSBalanceBucketsOutput.Section?,
        currentColumnTitle: String,
        previousColumnTitle: String,
        maps: RGSAssemblerResult,
        options: Options
    ) -> ComparativeSection? {
        guard current != nil || previous != nil else {
            return nil
        }

        let currentRows = (current?.lines ?? []).map {
            ComparativeMergeSeed(
                id: $0.id,
                label: $0.label,
                amount: $0.amount,
                direction: $0.direction,
                orientation: $0.orientation
            )
        }

        let previousRows = (previous?.lines ?? []).map {
            ComparativeMergeSeed(
                id: $0.id,
                label: $0.label,
                amount: $0.amount,
                direction: $0.direction,
                orientation: $0.orientation
            )
        }

        return buildComparativeSection(
            kind: .balance(kind),
            title: title,
            currentRows: currentRows,
            previousRows: previousRows,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle,
            currentSubtotal: current?.subtotal,
            previousSubtotal: previous?.subtotal,
            maps: maps,
            options: options
        )
    }

    static func buildComparativeSection(
        kind: TableSectionKind,
        title: String,
        currentRows: [ComparativeMergeSeed],
        previousRows: [ComparativeMergeSeed],
        currentColumnTitle: String,
        previousColumnTitle: String,
        currentSubtotal: Decimal?,
        previousSubtotal: Decimal?,
        maps: RGSAssemblerResult,
        options: Options
    ) -> ComparativeSection {
        let columns = [
            ComparativeAmountColumn(title: currentColumnTitle),
            ComparativeAmountColumn(title: previousColumnTitle),
        ]

        let currentById = Dictionary(
            uniqueKeysWithValues: currentRows.map { ($0.id, $0) }
        )

        let previousById = Dictionary(
            uniqueKeysWithValues: previousRows.map { ($0.id, $0) }
        )

        let mergedIds = Array(
            Set(currentRows.map(\.id)).union(previousRows.map(\.id))
        )
        .sorted {
            canonicalComparativeRowOrder(
                $0,
                $1,
                maps: maps,
                currentById: currentById,
                previousById: previousById
            )
        }

        let hierarchy = RenderedRowHierarchyBuilder.makeMap(
            idsInOrder: mergedIds,
            parentById: maps.parentById
        )

        let rows: [ComparativeRow] = mergedIds.compactMap { id in
            guard let base = currentById[id] ?? previousById[id] else {
                return nil
            }

            let h = hierarchy[id]
            let depth = h?.depth ?? 0

            let prefix = hierarchyPrefix(
                depth: depth,
                hasNextSibling: h?.hasNextSibling ?? false,
                ancestorHasNextSiblings: h?.ancestorHasNextSiblings ?? [],
                options: options
            )

            return ComparativeRow(
                id: id,
                parentId: h?.parentId,
                depth: depth,
                prefix: prefix,
                label: base.label,
                cells: [
                    currentById[id].map { .value($0.amount) } ?? .blank,
                    previousById[id].map { .value($0.amount) } ?? .blank,
                ],
                direction: base.direction,
                orientation: base.orientation,
                isTotal: false
            )
        }

        return ComparativeSection(
            kind: kind,
            title: title,
            columns: columns,
            rows: rows,
            subtotalCells: [
                comparativeAmountCell(currentSubtotal),
                comparativeAmountCell(previousSubtotal),
            ]
        )
    }

    @inline(__always)
    static func canonicalComparativeRowOrder(
        _ lhs: Int,
        _ rhs: Int,
        maps: RGSAssemblerResult,
        currentById: [Int: ComparativeMergeSeed],
        previousById: [Int: ComparativeMergeSeed]
    ) -> Bool {
        let lhsKey = maps.sortKeyById[lhs]
        let rhsKey = maps.sortKeyById[rhs]

        switch (lhsKey, rhsKey) {
        case let (.some(a), .some(b)):
            if a != b {
                return a < b
            }

        case (.some, nil):
            return true

        case (nil, .some):
            return false

        case (nil, nil):
            break
        }

        let lhsLabel = currentById[lhs]?.label ?? previousById[lhs]?.label ?? ""
        let rhsLabel = currentById[rhs]?.label ?? previousById[rhs]?.label ?? ""

        let labelCompare = lhsLabel.localizedStandardCompare(rhsLabel)
        if labelCompare != .orderedSame {
            return labelCompare == .orderedAscending
        }

        return lhs < rhs
    }

    static func buildComparativeSummary(
        current: BalanceSummary?,
        previous: BalanceSummary?,
        currentColumnTitle: String,
        previousColumnTitle: String
    ) -> ComparativeBalanceSummary? {
        guard let current else {
            return nil
        }

        return ComparativeBalanceSummary(
            currentTitle: currentColumnTitle,
            previousTitle: previousColumnTitle,
            currentAssets: current.assets,
            previousAssets: previous?.assets,
            currentEquity: current.equity,
            previousEquity: previous?.equity,
            currentLiabilities: current.liabilities,
            previousLiabilities: previous?.liabilities
        )
    }

    static func buildComparativeRatiosSection(
        current: RatiosSection?,
        previous: RatiosSection?,
        currentColumnTitle: String,
        previousColumnTitle: String
    ) -> ComparativeRatiosSection? {
        guard let current else {
            return nil
        }

        var previousRowsByLabel: [String: RatioRow] = [:]
        for row in previous?.rows ?? [] {
            previousRowsByLabel[row.label] = row
        }

        let rows = current.rows.map { row in
            let previousRow = previousRowsByLabel[row.label]

            return ComparativeRatioRow(
                label: row.label,
                description: row.description,
                formula: row.formula,
                currentValue: row.value,
                previousValue: previousRow?.value,
                style: row.style
            )
        }

        return ComparativeRatiosSection(
            title: current.title,
            currentTitle: currentColumnTitle,
            previousTitle: previousColumnTitle,
            rows: rows
        )
    }

    @inline(__always)
    static func comparativeAmountCell(
        _ amount: Decimal?
    ) -> ComparativeAmountCell {
        guard let amount else {
            return .blank
        }

        return .value(amount)
    }

    static func comparativeColumnTitle(
        for period: PeriodAssembleResultPeriod
    ) -> String {
        let calendar = Calendar(identifier: .gregorian)

        switch (period.range.from, period.range.to) {
        case let (.some(from), .some(to)):
            let fromYear = calendar.component(.year, from: from)
            let toYear = calendar.component(.year, from: to)

            if fromYear == toYear {
                return String(toYear)
            }

            return period.range.string()

        case let (_, .some(to)):
            return String(calendar.component(.year, from: to))

        default:
            return period.range.string()
        }
    }
}
