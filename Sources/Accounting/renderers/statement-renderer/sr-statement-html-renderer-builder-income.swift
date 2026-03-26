import Foundation

extension StatementHTMLRenderer {
    static func buildIncomeSection(
        from lines: [StatementLine],
        maps: RGSAssemblerResult,
        options: Options
    ) -> TableSection {
        let filtered = lines.filter { line in
            options.minAbsIncome == 0
                ? true
                : DecimalFuncs.absDec(line.amount) >= options.minAbsIncome
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
}
