import Foundation

public struct VATPresentation: Presentation {
    public typealias Input = BundlePresentationInput
    public typealias Output = VATOverview

    public static let id = "vat"
    public static let title = "VAT overview"

    public let reportTitle: String
    public let includeCorrections: Bool
    public let minAbs: Decimal

    public init(
        reportTitle: String = "BTW / Taxes Overview",
        includeCorrections: Bool = true,
        minAbs: Decimal = 0
    ) {
        self.reportTitle = reportTitle
        self.includeCorrections = includeCorrections
        self.minAbs = minAbs
    }

    public func build(from input: Input) throws -> Output {
        try RGSAssembler.vatOverview(
            reportTitle,
            bundle: input.bundle,
            chart: input.chart,
            includeCorrections: includeCorrections,
            minAbs: minAbs
        )
    }
}
