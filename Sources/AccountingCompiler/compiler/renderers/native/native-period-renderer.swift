import Accounting
import Foundation

public enum NativePeriodRenderer {
    public static func render(
        _ output: NativePeriodCompileOutput,
        options: NativeRenderOptions = .init()
    ) throws {
        var opts = options
        opts.periodShape = options.periodShape ?? output.shape
        let presentation = opts.presentationOptions()

        try renderPeriod(
            titleBalance: "Balance Sheet (current)",
            titleIncome: "Income Statement (current)",
            period: output.assembled.current,
            chart: output.chart,
            entities: output.result.entities,
            options: opts,
            presentation: presentation
        )

        guard options.comparePrevious,
              let previous = output.assembled.previous
        else {
            return
        }

        print("")

        try renderPeriod(
            titleBalance: "Balance Sheet (previous)",
            titleIncome: "Income Statement (previous)",
            period: previous,
            chart: output.chart,
            entities: output.result.entities,
            options: opts,
            presentation: presentation
        )
    }

    private static func renderPeriod(
        titleBalance: String,
        titleIncome: String,
        period: PeriodAssembleResultPeriod,
        chart: CompiledChart,
        entities: EntityStore,
        options: NativeRenderOptions,
        presentation: PresentationPrintOptions
    ) throws {
        if options.showRangeHeading {
            print(period.range.string())
        }

        do {
            try RGSAssembler.assertBalancedByL2(
                chart: chart,
                bundle: period.bundle,
                equityCode: options.equityCode
            )
        } catch {
            fputs("warning: \(error.localizedDescription)\n", stderr)
        }

        try RGSPrinter.printBalanceByL2Buckets(
            titleBalance,
            bundle: period.bundle,
            chart: chart,
            equityCode: options.equityCode,
            includeOtherBucket: options.includeOtherBucket,
            showEntityBreakdown: options.showEntityBreakdown,
            entities: entities,
            options: presentation
        )

        try RGSPrinter.printLines(
            titleIncome,
            lines: period.bundle.income,
            bundle: period.bundle,
            chart: chart,
            showEntityBreakdown: options.showEntityBreakdown,
            entities: entities,
            options: presentation
        )

        if options.showRatios {
            renderRatios(
                period.bundle.analytics?.ratios
            )
        }

        if options.showAverages {
            renderAverages(
                period.bundle.analytics?.averages
            )
        }
    }
}

public extension NativePeriodCompileOutput {
    func renderNative(
        options: NativeRenderOptions = .init()
    ) throws {
        try NativePeriodRenderer.render(
            self,
            options: options
        )
    }
}
