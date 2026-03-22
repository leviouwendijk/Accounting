import Foundation

public enum KIAProjection {
    public static func run(
        entities: EntityStore,
        request: KIAProjectionRequest,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> KIAProjectionResult {
        let assessed = KIAAssetAssessor.assess(
            entities: entities,
            taxYear: request.period.taxYear,
            calendar: calendar
        )

        let total = assessed.qualified.reduce(Decimal(0)) { $0 + $1.qualifyingAmount }

        let deduction = KIACalculator.compute(
            qualifyingInvestmentTotal: total,
            config: request.config
        )

        return KIAProjectionResult(
            taxYear: request.period.taxYear,
            qualifyingInvestmentTotal: total,
            deduction: deduction,
            qualifiedAssets: assessed.qualified,
            excludedAssets: assessed.excluded
        )
    }
}
