import Accounting
import Foundation
import HTML

public extension KIARenderer {
    @HTMLBuilder
    static func renderBody(
        _ result: KIAProjectionResult,
        title: String? = nil,
        subtitle: String? = nil,
        verbose: Bool = false,
        diagnostics: Bool = false,
        currencySymbol: String = "€"
    ) -> [any HTMLNode] {
        let resolvedTitle = title ?? "KIA \(result.taxYear)"
        let ownerSummaries = kiaOwnerDeductionSummaries(result)
        let diagnosticSummary = kiaSummarizeDiagnostics(result.diagnostics)

        HTML.h1 {
            HTML.text(resolvedTitle)
        }

        if let subtitle {
            HTML.div(["class": "subtitle"]) {
                HTML.text(subtitle)
            }
        }

        HTML.div(["class": "summary"]) {
            HTML.text("Qualifying investment total: \(kiaFmt(result.qualifyingInvestmentTotal, currencySymbol: currencySymbol))")
        }
        HTML.div(["class": "summary"]) {
            HTML.text("Deduction: \(kiaFmt(result.deduction, currencySymbol: currencySymbol))")
        }
        HTML.div(["class": "summary"]) {
            HTML.text("Qualified assets: \(result.qualifiedAssets.count)")
        }
        HTML.div(["class": "summary"]) {
            HTML.text("Excluded assets: \(result.excludedAssets.count)")
        }

        if !ownerSummaries.isEmpty {
            HTML.h2 {
                HTML.text("Deduction by owner")
            }

            HTML.table(["class": "tbl tbl-kia-owner"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th(["class": "col-owner"]) {
                            HTML.text("Owner")
                        }
                        HTML.th(["class": "col-money"]) {
                            HTML.text("Qualifying amount")
                        }
                        HTML.th(["class": "col-money"]) {
                            HTML.text("Deduction amount")
                        }
                    }
                }
                HTML.tbody {
                    for owner in ownerSummaries {
                        HTML.tr {
                            HTML.td(["class": "col-owner kia-cell-wrap"]) {
                                HTML.span(["class": "kia-cell-main"]) {
                                    HTML.text(owner.ownerLabel)
                                }
                            }
                            HTML.td(["class": "col-money"]) {
                                HTML.text(
                                    kiaFmt(
                                        owner.qualifyingAmount,
                                        currencySymbol: currencySymbol
                                    )
                                )
                            }
                            HTML.td(["class": "col-money"]) {
                                HTML.text(
                                    kiaFmt(
                                        owner.deductionAmount,
                                        currencySymbol: currencySymbol
                                    )
                                )
                            }
                        }
                    }
                }
            }
        }

        if diagnostics {
            HTML.h2 {
                HTML.text("Diagnostics summary")
            }

            HTML.div(["class": "summary"]) {
                HTML.text("Inspected entities: \(result.diagnostics.count)")
            }
            HTML.div(["class": "summary"]) {
                HTML.text("Candidate entities: \(result.diagnostics.filter { $0.wasCandidate }.count)")
            }
            HTML.div(["class": "summary"]) {
                HTML.text("Qualified outcomes: \(diagnosticSummary.qualifiedCount)")
            }
            HTML.div(["class": "summary"]) {
                HTML.text("Excluded outcomes: \(diagnosticSummary.excludedCount)")
            }

            if !diagnosticSummary.reasonCounts.isEmpty {
                HTML.h2 {
                    HTML.text("Exclusion reasons")
                }

                HTML.table(["class": "tbl"]) {
                    HTML.thead {
                        HTML.tr {
                            HTML.th {
                                HTML.text("Reason")
                            }
                            HTML.th(["style": "text-align: right;"]) {
                                HTML.text("Count")
                            }
                        }
                    }
                    HTML.tbody {
                        for item in diagnosticSummary.reasonCounts.sorted(by: { lhs, rhs in
                            if lhs.value == rhs.value {
                                return lhs.key < rhs.key
                            }

                            return lhs.value > rhs.value
                        }) {
                            HTML.tr {
                                HTML.td {
                                    HTML.text(item.key)
                                }
                                HTML.td(["style": "text-align: right; white-space: nowrap;"]) {
                                    HTML.text(String(item.value))
                                }
                            }
                        }
                    }
                }
            }
        }

        if !result.qualifiedAssets.isEmpty {
            HTML.h2 {
                HTML.text("Qualified assets")
            }

            HTML.table(["class": "tbl tbl-kia-qualified"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th(["class": "col-asset"]) {
                            HTML.text("Asset")
                        }
                        HTML.th(["class": "col-date"]) {
                            HTML.text("Acquisition date")
                        }
                        HTML.th(["class": "col-money"]) {
                            HTML.text("Total amount")
                        }
                        HTML.th(["class": "col-money"]) {
                            HTML.text("Qualifying amount")
                        }
                        HTML.th(["class": "col-shares"]) {
                            HTML.text("Shares")
                        }
                    }
                }
                HTML.tbody {
                    for asset in result.qualifiedAssets {
                        HTML.tr {
                            HTML.td(["class": "col-asset kia-cell-wrap"]) {
                                HTML.span(["class": "kia-cell-main"]) {
                                    HTML.text(asset.displayName)
                                }

                                HTML.span(["class": "kia-cell-meta"]) {
                                    HTML.text(
                                        asset.entityKey.identifier(
                                            displaying: .fullchain
                                        )
                                    )
                                }

                                if let details = asset.details, !details.isEmpty {
                                    HTML.span(["class": "kia-cell-meta"]) {
                                        HTML.text(details)
                                    }
                                }
                            }

                            HTML.td(["class": "col-date"]) {
                                HTML.text(kiaDateString(asset.acquisitionDate))
                            }

                            HTML.td(["class": "col-money"]) {
                                HTML.text(
                                    kiaFmt(
                                        asset.totalAmount,
                                        currencySymbol: currencySymbol
                                    )
                                )
                            }

                            HTML.td(["class": "col-money"]) {
                                HTML.text(
                                    kiaFmt(
                                        asset.qualifyingAmount,
                                        currencySymbol: currencySymbol
                                    )
                                )
                            }

                            HTML.td(["class": "col-shares kia-cell-wrap"]) {
                                if asset.shares.isEmpty {
                                    HTML.span(["class": "kia-cell-main"]) {
                                        HTML.text("none")
                                    }
                                } else {
                                    HTML.table(["class": "kia-share-table"]) {
                                        HTML.tbody {
                                            for share in asset.shares {
                                                HTML.tr {
                                                    HTML.td(["class": "kia-share-label"]) {
                                                        HTML.text(
                                                            "\(share.ownerLabel): \(kiaNumber(share.percentage))%"
                                                        )
                                                    }

                                                    HTML.td(["class": "kia-share-amount"]) {
                                                        HTML.text(
                                                            kiaFmt(
                                                                share.amount,
                                                                currencySymbol: currencySymbol
                                                            )
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if verbose && !result.excludedAssets.isEmpty {
            HTML.h2 {
                HTML.text("Excluded assets")
            }

            HTML.table(["class": "tbl"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th {
                            HTML.text("Asset")
                        }
                        HTML.th {
                            HTML.text("Reason")
                        }
                    }
                }
                HTML.tbody {
                    for excluded in result.excludedAssets {
                        HTML.tr {
                            HTML.td {
                                HTML.text(excluded.entityKey.identifier(displaying: .fullchain))
                            }
                            HTML.td {
                                HTML.text(kiaReasonString(excluded.reason, currencySymbol: currencySymbol))
                            }
                        }
                    }
                }
            }
        }

        if diagnostics {
            HTML.h2 {
                HTML.text("Per-entity diagnostics")
            }

            HTML.table(["class": "tbl"]) {
                HTML.thead {
                    HTML.tr {
                        HTML.th {
                            HTML.text("Entity")
                        }
                        HTML.th {
                            HTML.text("Display name")
                        }
                        HTML.th {
                            HTML.text("Candidate")
                        }
                        HTML.th {
                            HTML.text("Commission date")
                        }
                        HTML.th(["style": "text-align: right;"]) {
                            HTML.text("Acquisition cost")
                        }
                        HTML.th {
                            HTML.text("Share summary")
                        }
                        HTML.th {
                            HTML.text("Outcome")
                        }
                    }
                }
                HTML.tbody {
                    for record in result.diagnostics {
                        HTML.tr {
                            HTML.td {
                                HTML.text(record.entityKey.identifier(displaying: .fullchain))
                            }
                            HTML.td {
                                HTML.text(record.displayName)
                            }
                            HTML.td {
                                HTML.text(record.wasCandidate ? "yes" : "no")
                            }
                            HTML.td(["style": "white-space: nowrap;"]) {
                                HTML.text(record.commissionDate.map(kiaDateString) ?? "—")
                            }
                            HTML.td(["style": "text-align: right; white-space: nowrap;"]) {
                                HTML.text(record.acquisitionCost.map { kiaFmt($0, currencySymbol: currencySymbol) } ?? "—")
                            }
                            HTML.td {
                                HTML.text(record.shareSummary ?? "—")
                            }
                            HTML.td {
                                HTML.text(kiaOutcomeString(record.outcome, currencySymbol: currencySymbol))
                            }
                        }
                    }
                }
            }
        }
    }

    static func renderHTML(
        _ result: KIAProjectionResult,
        title: String? = nil,
        subtitle: String? = nil,
        verbose: Bool = false,
        diagnostics: Bool = false,
        currencySymbol: String = "€"
    ) -> String {
        let resolvedTitle = title ?? "KIA \(result.taxYear)"
        let css = StatementStyleCSS.base().render()

        let doc: HTMLDocument = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(.charset())
                    HTML.meta(.viewport())
                    HTML.title(resolvedTitle)
                    HTML.style(css)
                }

                HTML.body(["class": "sr-kia"]) {
                    renderBody(
                        result,
                        title: resolvedTitle,
                        subtitle: subtitle,
                        verbose: verbose,
                        diagnostics: diagnostics,
                        currencySymbol: currencySymbol
                    )
                }
            }
        }

        return doc.render(
            default: HTMLDocument.RenderDefault.minified,
            doctype: true
        )
    }
}

private struct KIAHTMLDeductionSummary: Sendable, Hashable {
    let ownerLabel: String
    let qualifyingAmount: Decimal
    let deductionAmount: Decimal
}

private func kiaOwnerDeductionSummaries(
    _ result: KIAProjectionResult
) -> [KIAHTMLDeductionSummary] {
    guard result.qualifyingInvestmentTotal > 0 else {
        return []
    }

    let ratio = result.deduction / result.qualifyingInvestmentTotal
    var totalsByOwner: [String: Decimal] = [:]

    for asset in result.qualifiedAssets {
        for share in asset.shares {
            totalsByOwner[share.ownerLabel, default: 0] += share.amount
        }
    }

    return totalsByOwner
        .map { ownerLabel, qualifyingAmount in
            KIAHTMLDeductionSummary(
                ownerLabel: ownerLabel,
                qualifyingAmount: qualifyingAmount,
                deductionAmount: qualifyingAmount * ratio
            )
        }
        .sorted { lhs, rhs in
            lhs.ownerLabel < rhs.ownerLabel
        }
}

private func kiaSummarizeDiagnostics(
    _ diagnostics: [KIADiagnosticRecord]
) -> (
    qualifiedCount: Int,
    excludedCount: Int,
    reasonCounts: [String: Int]
) {
    var qualifiedCount = 0
    var excludedCount = 0
    var reasonCounts: [String: Int] = [:]

    for record in diagnostics {
        switch record.outcome {
        case .qualified:
            qualifiedCount += 1

        case .excluded(let reason):
            excludedCount += 1
            let key = kiaReasonString(reason, currencySymbol: "€")
            reasonCounts[key, default: 0] += 1
        }
    }

    return (qualifiedCount, excludedCount, reasonCounts)
}

private func kiaOutcomeString(
    _ outcome: KIADiagnosticOutcome,
    currencySymbol: String
) -> String {
    switch outcome {
    case .qualified:
        return "qualified"
    case .excluded(let reason):
        return "excluded — \(kiaReasonString(reason, currencySymbol: currencySymbol))"
    }
}

private func kiaReasonString(
    _ reason: KIAQualificationReason,
    currencySymbol: String
) -> String {
    switch reason {
    case .missingDepreciation:
        return "missing depreciation"

    case .missingProfile:
        return "missing profile"

    case .missingCommissionDate:
        return "missing commission date"

    case .missingAcquisitionCost:
        return "missing acquisition cost"

    case .belowMinimumAssetAmount(let amount):
        return "below minimum asset amount (\(kiaFmt(amount, currencySymbol: currencySymbol)))"

    case .outsideTaxYear(let actualYear):
        if let actualYear {
            return "outside tax year (actual year: \(actualYear))"
        }

        return "outside tax year"

    case .invalidShareConfiguration(let message):
        return "invalid share configuration (\(message))"

    case .notAssetCandidate:
        return "not asset candidate"
    }
}

private func kiaDateString(
    _ date: Date
) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

private func kiaFmt(
    _ value: Decimal,
    currencySymbol: String
) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.numberStyle = .currency
    formatter.currencySymbol = currencySymbol
    formatter.minimumFractionDigits = 2
    formatter.maximumFractionDigits = 2

    return formatter.string(from: value as NSDecimalNumber)
        ?? value.description
}

private func kiaNumber(
    _ value: Decimal
) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale(identifier: "nl_NL")
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2

    return formatter.string(from: value as NSDecimalNumber)
        ?? value.description
}
