import Accounting
import Foundation

struct CanonicalRootAmountResolver: Sendable {
    let idByCode: [String: Int]
    let totalsById: [Int: Decimal]
    let directionById: [Int: Direction]
    let omslag: OmslagMode
    let minAbs: Decimal

    init(
        chart: CompiledChart,
        bundle: StatementBundle,
        maps: RGSAssemblerResult,
        omslag: OmslagMode,
        minAbs: Decimal = 0
    ) {
        self.idByCode = Dictionary(
            uniqueKeysWithValues: chart.nodes.map { ($0.codes.code, $0.id) }
        )
        self.totalsById = bundle.totalsById
        self.directionById = maps.directionById
        self.omslag = omslag
        self.minAbs = minAbs
    }

    @inline(__always)
    func shownAmount(
        for code: String?
    ) -> Decimal? {
        guard let code, let id = idByCode[code] else {
            return nil
        }

        let raw = totalsById[id] ?? 0
        let dir = directionById[id] ?? .debit

        let shown = RGSAssembler.present(
            raw,
            direction: dir,
            mode: omslag
        )

        if minAbs > 0, DecimalFuncs.absDec(shown) < minAbs {
            return nil
        }

        return shown
    }

    @inline(__always)
    func shownAmount(
        for codes: [String]
    ) -> Decimal? {
        let values = codes.compactMap { shownAmount(for: $0) }

        guard !values.isEmpty else {
            return nil
        }

        return values.reduce(0, +)
    }

    @inline(__always)
    func shownAmountsByCode(
        for codes: [String]
    ) -> [(code: String, amount: Decimal)] {
        codes.compactMap { code in
            guard let amount = shownAmount(for: code) else {
                return nil
            }

            return (code, amount)
        }
    }
}
