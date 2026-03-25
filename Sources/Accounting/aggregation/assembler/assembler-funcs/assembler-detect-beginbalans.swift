import Foundation

extension RGSAssembler {
    @inline(__always)
    public static func openingBegSeed(
        from tbHist: [TrialBalanceRow],
        chart: CompiledChart,
        index: RGSIndex,
        maps: RGSAssemblerResult
    ) -> [Int: Decimal] {
        // build a quick id → identifier code map
        let codeById: [Int:String] = Dictionary(uniqueKeysWithValues: chart.nodes.map { ($0.id, $0.codes.code) })

        var out: [Int: Decimal] = [:]
        for r in tbHist {
            guard let id = index.byIdentifier[r.accountCode] else { continue }
            // Only balance sheet
            guard maps.kindById[id] == .balance else { continue }

            // Try to reclass to parent’s "<parentCode>Beg" if that code exists
            let targetId: Int = {
                guard let pid = maps.parentById[id],
                      let pCode = codeById[pid]
                else { return id }

                let begCode = pCode + "Beg"
                if let begId = index.byIdentifier[begCode] { return begId }
                return id
            }()

            let amt = r.debit - r.credit
            if amt != 0 { out[targetId, default: 0] += amt }
        }
        return out
    }
}
