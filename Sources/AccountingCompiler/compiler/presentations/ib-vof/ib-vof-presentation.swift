import Accounting
import Foundation

public struct IBVOFPresentation: Presentation {
    public typealias Input = BundlePresentationInput
    public typealias Output = IBVOFOverview

    public static let id = "ib-vof"
    public static let title = "IB VOF overview"

    public let reportTitle: String
    public let businessEntity: BusinessEntity
    public let minAbs: Decimal

    public init(
        reportTitle: String = "IB VOF filing overview",
        businessEntity: BusinessEntity = .vof,
        minAbs: Decimal = 0
    ) {
        self.reportTitle = reportTitle
        self.businessEntity = businessEntity
        self.minAbs = minAbs
    }

    public func build(from input: Input) throws -> Output {
        try RGSAssembler.ibVOFOverview(
            reportTitle,
            bundle: input.bundle,
            chart: input.chart,
            businessEntity: businessEntity,
            minAbs: minAbs
        )
    }
}
