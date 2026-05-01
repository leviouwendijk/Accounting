import Accounting
import Foundation

extension AssetViews {
    public enum AssetFilingReconciliationBuilder {
        private enum Selector {
            case exact(String)
            case prefixAndSuffix(prefix: String, suffix: String)

            var label: String {
                switch self {
                case .exact(let code):
                    return code
                case .prefixAndSuffix(let prefix, let suffix):
                    return "\(prefix)*\(suffix)"
                }
            }
        }

        private struct Spec {
            let section: AssetsOverviewSection
            let metric: AssetFilingReconciliationMetric
            let projectedValue: (AssetsOverviewAmounts) -> Decimal
            let selector: Selector
        }

        public static func build(
            overview: AssetsOverview,
            chart: CompiledChart,
            bundle: StatementBundle,
            tolerance: Decimal = 0
        ) -> AssetFilingReconciliationReport {
            let totalsBySection = Dictionary(
                uniqueKeysWithValues: overview.groups.map { ($0.section, $0.totals) }
            )

            let specs: [Spec] = [
                .init(
                    section: .intangibleFixedAssets,
                    metric: .closingGrossCost,
                    projectedValue: { $0.acquisitionCost },
                    selector: .prefixAndSuffix(prefix: "BIva", suffix: "Vvp")
                ),
                .init(
                    section: .intangibleFixedAssets,
                    metric: .periodInvestments,
                    projectedValue: { $0.periodInvestment },
                    selector: .prefixAndSuffix(prefix: "BIva", suffix: "VvpIna")
                ),
                .init(
                    section: .intangibleFixedAssets,
                    metric: .closingCarryingAmount,
                    projectedValue: { $0.closingCarryingAmount },
                    selector: .exact("BIva")
                ),

                .init(
                    section: .tangibleFixedAssets,
                    metric: .closingGrossCost,
                    projectedValue: { $0.acquisitionCost },
                    selector: .prefixAndSuffix(prefix: "BMva", suffix: "Vvp")
                ),
                .init(
                    section: .tangibleFixedAssets,
                    metric: .periodInvestments,
                    projectedValue: { $0.periodInvestment },
                    selector: .prefixAndSuffix(prefix: "BMva", suffix: "VvpIna")
                ),
                .init(
                    section: .tangibleFixedAssets,
                    metric: .closingCarryingAmount,
                    projectedValue: { $0.closingCarryingAmount },
                    selector: .exact("BMva")
                ),
            ]

            var rows: [AssetFilingReconciliationRow] = []

            for spec in specs {
                let projected = totalsBySection[spec.section]
                    .map(spec.projectedValue) ?? 0

                let resolved = resolve(
                    selector: spec.selector,
                    chart: chart,
                    bundle: bundle
                )

                let difference = rounded(projected - resolved.total)
                let passed = absolute(difference) <= tolerance

                var notes: [String] = []
                if resolved.matchedCodes.isEmpty {
                    notes.append("no ledger codes matched selector")
                }

                rows.append(
                    .init(
                        section: spec.section,
                        metric: spec.metric,
                        projected: rounded(projected),
                        ledger: resolved.total,
                        difference: difference,
                        ledgerSelector: spec.selector.label,
                        matchedCodes: resolved.matchedCodes,
                        notes: notes,
                        passed: passed
                    )
                )
            }

            let checkedSections = Set(specs.map(\.section))
            let uncheckedSections = Set(overview.groups.map(\.section))
                .subtracting(checkedSections)
                .sorted { lhs, rhs in
                    lhs.sortOrder < rhs.sortOrder
                }

            return .init(
                period: overview.period,
                tolerance: tolerance,
                rows: rows.sorted(by: sortRows),
                uncheckedSections: uncheckedSections
            )
        }

        private static func resolve(
            selector: Selector,
            chart: CompiledChart,
            bundle: StatementBundle
        ) -> (total: Decimal, matchedCodes: [String]) {
            var total: Decimal = 0
            var matchedCodes: [String] = []

            for node in chart.nodes {
                let code = node.codes.code

                let matched: Bool = {
                    switch selector {
                    case .exact(let expected):
                        return code == expected

                    case .prefixAndSuffix(let prefix, let suffix):
                        return code.hasPrefix(prefix) && code.hasSuffix(suffix)
                    }
                }()

                guard matched else {
                    continue
                }

                total += bundle.totalsById[node.id] ?? 0
                matchedCodes.append(code)
            }

            return (
                total: rounded(total),
                matchedCodes: Array(Set(matchedCodes)).sorted()
            )
        }

        private static func sortRows(
            lhs: AssetFilingReconciliationRow,
            rhs: AssetFilingReconciliationRow
        ) -> Bool {
            if lhs.section != rhs.section {
                return lhs.section.sortOrder < rhs.section.sortOrder
            }

            if lhs.metric != rhs.metric {
                return lhs.metric.sortOrder < rhs.metric.sortOrder
            }

            return lhs.ledgerSelector < rhs.ledgerSelector
        }

        private static func rounded(
            _ value: Decimal
        ) -> Decimal {
            AccountingMoney.round(value)
        }

        private static func absolute(
            _ value: Decimal
        ) -> Decimal {
            value < 0 ? -value : value
        }
    }
}
