import Foundation

public enum NativePeriodRenderer {
    public static func render(
        _ output: NativePeriodCompileOutput,
        options: NativeRenderOptions = .init()
    ) throws {
        let presentation = options.presentationOptions()

        // try renderPeriod(
        //     titleBalance: "Balance Sheet (current)",
        //     titleIncome: "Income Statement (current)",
        //     period: output.assembled.current,
        //     chart: output.chart,
        //     options: options,
        //     presentation: presentation
        // )
        try renderPeriod(
            titleBalance: "Balance Sheet (current)",
            titleIncome: "Income Statement (current)",
            period: output.assembled.current,
            chart: output.chart,
            entities: output.result.entities,
            options: options,
            presentation: presentation
        )

        guard options.comparePrevious,
              let previous = output.assembled.previous
        else {
            return
        }

        print("")

        // try renderPeriod(
        //     titleBalance: "Balance Sheet (previous)",
        //     titleIncome: "Income Statement (previous)",
        //     period: previous,
        //     chart: output.chart,
        //     options: options,
        //     presentation: presentation
        // )
        try renderPeriod(
            titleBalance: "Balance Sheet (previous)",
            titleIncome: "Income Statement (previous)",
            period: previous,
            chart: output.chart,
            entities: output.result.entities,
            options: options,
            presentation: presentation
        )
    }

    // private static func renderPeriod(
    //     titleBalance: String,
    //     titleIncome: String,
    //     period: PeriodAssembleResultPeriod,
    //     chart: CompiledChart,
    //     options: NativeRenderOptions,
    //     presentation: PresentationPrintOptions
    // ) throws {
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

        // try RGSPrinter.printBalanceByL2Buckets(
        //     titleBalance,
        //     bundle: period.bundle,
        //     chart: chart,
        //     equityCode: options.equityCode,
        //     includeOtherBucket: options.includeOtherBucket,
        //     options: presentation
        // )
        // try RGSPrinter.printBalanceByL2Buckets(
        //     titleBalance,
        //     bundle: period.bundle,
        //     chart: chart,
        //     equityCode: options.equityCode,
        //     includeOtherBucket: options.includeOtherBucket,
        //     showEntityBreakdown: options.showEntityBreakdown,
        //     entities: output.result.entities,
        //     options: presentation
        // )
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

        // try RGSPrinter.printLines(
        //     titleIncome,
        //     lines: period.bundle.income,
        //     chart: chart,
        //     options: presentation
        // )

        try RGSPrinter.printLines(
            titleIncome,
            lines: period.bundle.income,
            bundle: period.bundle,
            chart: chart,
            showEntityBreakdown: options.showEntityBreakdown,
            entities: entities,
            options: presentation
        )
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
