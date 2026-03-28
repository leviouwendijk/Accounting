import Foundation

extension StatementHTMLRenderer {
    public static func renderComparative(
        output: NativePeriodCompileOutput,
        equityCode: String = "BEiv",
        options: Options = .init()
    ) throws -> String {
        guard let previous = output.assembled.previous else {
            return try render(
                period: output.assembled.current,
                chart: output.chart,
                equityCode: equityCode,
                options: options
            )
        }

        var opts = options
        opts.subtitle = output.assembled.current.range.string()

        return try renderComparative(
            current: output.assembled.current,
            previous: previous,
            chart: output.chart,
            equityCode: equityCode,
            currentColumnTitle: comparativeColumnTitle(for: output.assembled.current),
            previousColumnTitle: comparativeColumnTitle(for: previous),
            options: opts
        )
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
        let currentModel = try buildDocumentModel(
            bundle: current.bundle,
            chart: chart,
            equityCode: equityCode,
            options: options
        )

        let previousModel = try buildDocumentModel(
            bundle: previous.bundle,
            chart: chart,
            equityCode: equityCode,
            options: options
        )

        let comparativeModel = buildComparativeDocumentModel(
            current: currentModel,
            previous: previousModel,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle
        )

        return renderComparativeDocument(
            model: comparativeModel,
            options: options
        )
    }

    static func buildComparativeDocumentModel(
        current: DocumentModel,
        previous: DocumentModel,
        currentColumnTitle: String,
        previousColumnTitle: String
    ) -> ComparativeDocumentModel {
        let mergedIncome = mergeComparativeSection(
            current: current.income,
            previous: previous.income,
            currentColumnTitle: currentColumnTitle,
            previousColumnTitle: previousColumnTitle
        )

        var previousBalanceByKey: [String: TableSection] = [:]
        for section in previous.balances {
            previousBalanceByKey[comparativeSectionKey(section.kind)] = section
        }

        var mergedBalances: [ComparativeSection] = []

        for currentSection in current.balances {
            let key = comparativeSectionKey(currentSection.kind)
            let previousSection = previousBalanceByKey.removeValue(forKey: key)

            mergedBalances.append(
                mergeComparativeSection(
                    current: currentSection,
                    previous: previousSection,
                    currentColumnTitle: currentColumnTitle,
                    previousColumnTitle: previousColumnTitle
                )
            )
        }

        return ComparativeDocumentModel(
            income: mergedIncome,
            balances: mergedBalances,
            summary: buildComparativeSummary(
                current: current.summary,
                previous: previous.summary,
                currentColumnTitle: currentColumnTitle,
                previousColumnTitle: previousColumnTitle
            ),
            ratios: buildComparativeRatiosSection(
                current: current.ratios,
                previous: previous.ratios,
                currentColumnTitle: currentColumnTitle,
                previousColumnTitle: previousColumnTitle
            )
        )
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

    static func mergeComparativeSection(
        current: TableSection,
        previous: TableSection?,
        currentColumnTitle: String,
        previousColumnTitle: String
    ) -> ComparativeSection {
        let columns = [
            ComparativeAmountColumn(title: currentColumnTitle),
            ComparativeAmountColumn(title: previousColumnTitle),
        ]

        var currentRowsByKey: [String: TableRow] = [:]
        for row in current.rows {
            currentRowsByKey[comparativeRowKey(row)] = row
        }

        var previousRowsByKey: [String: TableRow] = [:]
        for row in previous?.rows ?? [] {
            previousRowsByKey[comparativeRowKey(row)] = row
        }

        var orderedKeys: [String] = []
        var seenKeys = Set<String>()

        for row in current.rows {
            let key = comparativeRowKey(row)
            if seenKeys.insert(key).inserted {
                orderedKeys.append(key)
            }
        }

        for row in previous?.rows ?? [] {
            let key = comparativeRowKey(row)
            if seenKeys.insert(key).inserted {
                orderedKeys.append(key)
            }
        }

        let mergedRows: [ComparativeRow] = orderedKeys.compactMap { key in
            let currentRow = currentRowsByKey[key]
            let previousRow = previousRowsByKey[key]

            guard let baseRow = currentRow ?? previousRow else {
                return nil
            }

            return ComparativeRow(
                id: baseRow.id,
                parentId: baseRow.parentId,
                depth: baseRow.depth,
                prefix: baseRow.prefix,
                label: baseRow.label,
                cells: [
                    currentRow.map { .value($0.amount) } ?? .blank,
                    previousRow.map { .value($0.amount) } ?? .blank,
                ],
                direction: baseRow.direction,
                orientation: baseRow.orientation,
                isTotal: baseRow.isTotal
            )
        }

        return ComparativeSection(
            kind: current.kind,
            title: current.title,
            columns: columns,
            rows: mergedRows,
            subtotalCells: [
                comparativeAmountCell(current.subtotal),
                comparativeAmountCell(previous?.subtotal),
            ]
        )
    }

    // static func mergeComparativeSection(
    //     current: TableSection,
    //     previous: TableSection?,
    //     currentColumnTitle: String,
    //     previousColumnTitle: String
    // ) -> ComparativeSection {
    //     let columns = [
    //         ComparativeAmountColumn(title: currentColumnTitle),
    //         ComparativeAmountColumn(title: previousColumnTitle),
    //     ]

    //     var previousRowsByKey: [String: TableRow] = [:]
    //     for row in previous?.rows ?? [] {
    //         previousRowsByKey[comparativeRowKey(row)] = row
    //     }

    //     let mergedRows: [ComparativeRow] = current.rows.map { row in
    //         let previousRow = previousRowsByKey[comparativeRowKey(row)]

    //         return ComparativeRow(
    //             id: row.id,
    //             parentId: row.parentId,
    //             depth: row.depth,
    //             prefix: row.prefix,
    //             label: row.label,
    //             cells: [
    //                 .value(row.amount),
    //                 previousRow.map { .value($0.amount) } ?? .blank,
    //             ],
    //             direction: row.direction,
    //             orientation: row.orientation,
    //             isTotal: row.isTotal
    //         )
    //     }

    //     return ComparativeSection(
    //         kind: current.kind,
    //         title: current.title,
    //         columns: columns,
    //         rows: mergedRows,
    //         subtotalCells: [
    //             comparativeAmountCell(current.subtotal),
    //             comparativeAmountCell(previous?.subtotal),
    //         ]
    //     )
    // }

    @inline(__always)
    static func comparativeAmountCell(
        _ amount: Decimal?
    ) -> ComparativeAmountCell {
        guard let amount else {
            return .blank
        }

        return .value(amount)
    }

    @inline(__always)
    static func comparativeSectionKey(
        _ kind: TableSectionKind
    ) -> String {
        switch kind {
        case .incomeStatement:
            return "income"

        case .balance(.assets):
            return "balance.assets"

        case .balance(.equity):
            return "balance.equity"

        case .balance(.liabilities):
            return "balance.liabilities"

        case .balance(.other):
            return "balance.other"
        }
    }

    @inline(__always)
    static func comparativeRowKey(
        _ row: TableRow
    ) -> String {
        if let id = row.id {
            return "id:\(id)"
        }

        return [
            "label:\(row.label)",
            "depth:\(row.depth)",
            "parent:\(row.parentId.map(String.init) ?? "nil")",
            "total:\(row.isTotal)",
        ].joined(separator: "|")
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
