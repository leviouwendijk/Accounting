import Foundation

public enum NativeCompileRenderer {
    public static func render(
        _ output: NativeCompileOutput,
        options: NativeRenderOptions = .init()
    ) throws {
        do {
            try RGSAssembler.assertBalancedByL2(
                chart: output.chart,
                bundle: output.bundle,
                equityCode: options.equityCode
            )
        } catch {
            fputs("warning: \(error.localizedDescription)\n", stderr)
        }

        let presentation = options.presentationOptions()

        try RGSPrinter.printBalanceByL2Buckets(
            "Balance Sheet (assembled)",
            bundle: output.bundle,
            chart: output.chart,
            equityCode: options.equityCode,
            includeOtherBucket: options.includeOtherBucket,
            options: presentation
        )

        try RGSPrinter.printLines(
            "Income Statement (assembled)",
            lines: output.bundle.income,
            chart: output.chart,
            options: presentation
        )
    }
}

public extension NativeCompileOutput {
    func renderNative(
        options: NativeRenderOptions = .init()
    ) throws {
        try NativeCompileRenderer.render(
            self,
            options: options
        )
    }
}
