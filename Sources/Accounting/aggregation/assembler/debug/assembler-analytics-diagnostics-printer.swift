import Foundation

public extension RGSAssembler {
    static func printAnalyticsDiagnostics(
        _ analytics: BundleAnalytics,
        title: String = "Analytics diagnostics",
        includeNilBuckets: Bool = false
    ) {
        print(title)
        print(String(repeating: "─", count: title.count))

        if let diagnostics = analytics.diagnostics {
            let buckets = includeNilBuckets
                ? diagnostics.buckets
                : diagnostics.buckets.filter { $0.amount != nil }

            if !buckets.isEmpty {
                print("")
                print("Resolved buckets")
                print("────────────────")

                for row in buckets {
                    let amount = analyticsDiagnosticValue(row.amount)
                    let requested = analyticsDiagnosticCodes(row.codes)
                    let resolved = analyticsDiagnosticCodes(row.resolvedCodes)

                    var line = "- \(row.label): \(amount) | requested: \(requested) | resolved: \(resolved)"

                    if !row.fallbackCodes.isEmpty {
                        let fallbackRequested = analyticsDiagnosticCodes(
                            row.fallbackCodes
                        )
                        let fallbackResolved = analyticsDiagnosticCodes(
                            row.resolvedFallbackCodes
                        )

                        line += " | fallback requested: \(fallbackRequested)"
                        line += " | fallback resolved: \(fallbackResolved)"
                    }

                    if row.usedFallback {
                        line += " | used fallback"
                    }

                    print(line)
                }
            }

            let derived = includeNilBuckets
                ? diagnostics.derived
                : diagnostics.derived.filter { $0.amount != nil }

            if !derived.isEmpty {
                print("")
                print("Derived values")
                print("──────────────")

                for row in derived {
                    let amount = analyticsDiagnosticValue(row.amount)
                    print("- \(row.label): \(amount) | \(row.formula)")
                }
            }
        }

        if let inputs = analytics.ratioInputs {
            print("")
            print("Resolved inputs")
            print("───────────────")
            print("- assets: \(inputs.assets)")
            print("- equity: \(inputs.equity)")
            print("- liabilities: \(inputs.liabilities)")
            print("- netTurnover: \(analyticsDiagnosticValue(inputs.netTurnover))")
            print("- costOfRevenue: \(analyticsDiagnosticValue(inputs.costOfRevenue))")
            print("- operatingExpenses: \(analyticsDiagnosticValue(inputs.operatingExpenses))")
            print("- depreciationExpenses: \(analyticsDiagnosticValue(inputs.depreciationExpenses))")
            print("- financialResult: \(analyticsDiagnosticValue(inputs.financialResult))")
            print("- netIncome: \(analyticsDiagnosticValue(inputs.netIncome))")
            print("- liquidAssets: \(analyticsDiagnosticValue(inputs.liquidAssets))")
            print("- shortTermSecurities: \(analyticsDiagnosticValue(inputs.shortTermSecurities))")
            print("- receivables: \(analyticsDiagnosticValue(inputs.receivables))")
            print("- accruedCurrentAssets: \(analyticsDiagnosticValue(inputs.accruedCurrentAssets))")
            print("- inventory: \(analyticsDiagnosticValue(inputs.inventory))")
            print("- workInProgress: \(analyticsDiagnosticValue(inputs.workInProgress))")
            print("- currentLiabilities: \(analyticsDiagnosticValue(inputs.currentLiabilities))")
            print("- accruedCurrentLiabilities: \(analyticsDiagnosticValue(inputs.accruedCurrentLiabilities))")
            print("- grossProfit: \(analyticsDiagnosticValue(inputs.grossProfit))")
            print("- totalBusinessExpenses: \(analyticsDiagnosticValue(inputs.totalBusinessExpenses))")
            print("- operatingResult: \(analyticsDiagnosticValue(inputs.operatingResult))")
            print("- totalCurrentAssets: \(analyticsDiagnosticValue(inputs.totalCurrentAssets))")
            print("- quickAssets: \(analyticsDiagnosticValue(inputs.quickAssets))")
            print("- totalCurrentLiabilities: \(analyticsDiagnosticValue(inputs.totalCurrentLiabilities))")
        }

        if let ratios = analytics.ratios {
            print("")
            print("Ratios")
            print("──────")
            print("- equityRatio: \(analyticsDiagnosticValue(ratios.equityRatio))")
            print("- debtRatio: \(analyticsDiagnosticValue(ratios.debtRatio))")
            print("- debtToEquity: \(analyticsDiagnosticValue(ratios.debtToEquity))")
            print("- equityMultiplier: \(analyticsDiagnosticValue(ratios.equityMultiplier))")
            print("- currentRatio: \(analyticsDiagnosticValue(ratios.currentRatio))")
            print("- quickRatio: \(analyticsDiagnosticValue(ratios.quickRatio))")
            print("- grossMargin: \(analyticsDiagnosticValue(ratios.grossMargin))")
            print("- operatingMargin: \(analyticsDiagnosticValue(ratios.operatingMargin))")
            print("- netMargin: \(analyticsDiagnosticValue(ratios.netMargin))")
            print("- returnOnAssets: \(analyticsDiagnosticValue(ratios.returnOnAssets))")
            print("- returnOnEquity: \(analyticsDiagnosticValue(ratios.returnOnEquity))")
        }
    }
}

@inline(__always)
private func analyticsDiagnosticValue(
    _ value: Decimal?
) -> String {
    guard let value else {
        return "nil"
    }

    return String(describing: value)
}

@inline(__always)
private func analyticsDiagnosticCodes(
    _ codes: [String]
) -> String {
    guard !codes.isEmpty else {
        return "[]"
    }

    return codes.joined(separator: ", ")
}
