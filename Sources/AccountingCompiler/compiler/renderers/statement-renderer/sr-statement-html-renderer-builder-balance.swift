import Accounting
import Foundation

extension StatementHTMLRenderer {
    static func buildBalanceSection(
        kind: BalanceSectionKind,
        title: String,
        source: RGSBalanceBucketsOutput.Section?,
        chart: CompiledChart,
        maps: RGSAssemblerResult,
        options: Options
    ) -> TableSection? {
        guard let source else {
            return nil
        }

        let nodeById: [Int: RGSNode] = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.id, $0) }
        )

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

            let label = nodeById[line.id]?
                .presentationLabelIfNeeded(
                    .short,
                    shape: options.periodShape
                ) ?? line.label

            return TableRow(
                id: line.id,
                parentId: h?.parentId,
                depth: depth,
                prefix: prefix,
                // label: line.label,
                label: label,
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
