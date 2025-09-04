import Foundation

extension RGSAssembler {
    public static func makeL2Buckets(
        chart: CompiledChart,
        defaultEquityCode: String = "BEiv"
    ) throws -> L2Buckets {
        let maps = try makeMaps(from: chart)

        // Level 2 balance nodes
        let l2 = chart.nodes.filter { $0.level == 2 && maps.kindById[$0.id] == .balance }

        // Find equity anchor by identifier code
        let eqId: Int? = l2.first(where: { $0.codes.code == defaultEquityCode })?.id
        guard let equityId = eqId else {
            throw L2BucketError.equityAnchorNotFound(code: defaultEquityCode)
        }
        guard let eqNode = chart.nodes.first(where: { $0.id == equityId }) else {
            throw L2BucketError.equityAnchorNotFound(code: defaultEquityCode)
        }
        guard eqNode.level == 2 else {
            throw L2BucketError.equityAnchorWrongLevel(code: defaultEquityCode, got: eqNode.level)
        }
        guard maps.directionById[equityId] == .credit else {
            throw L2BucketError.equityAnchorWrongDirection(code: defaultEquityCode, got: maps.directionById[equityId])
        }

        // Partition by direction, excluding the equity anchor from liabilities
        var assets: [Int] = []
        var liabilities: [Int] = []
        for n in l2 {
            if n.id == equityId { continue }
            switch maps.directionById[n.id] ?? .debit {
            case .debit:  assets.append(n.id)
            case .credit: liabilities.append(n.id)
            }
        }

        return .init(assets: assets, equity: equityId, liabilities: liabilities)
    }
}
