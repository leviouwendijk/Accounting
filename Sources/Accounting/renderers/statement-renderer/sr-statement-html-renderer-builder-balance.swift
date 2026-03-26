import Foundation

extension StatementHTMLRenderer {
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
}
