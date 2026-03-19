import Foundation

public struct AutoCloseTargets: Sendable, Codable {
    public let netIncomeCode: String   // e.g. "WNerKap" (EZ/VOF) or "WNerNewNew" (BV L4)…
    public let retainedEarningsCode: String // e.g. "BEivOreOvw"
    
    public init(
        netIncomeCode: String,
        retainedEarningsCode: String
    ) {
        self.netIncomeCode = netIncomeCode
        self.retainedEarningsCode = retainedEarningsCode
    }


    public init(for businessEntity: BusinessEntity) {
        self = businessEntity.autoCloseTargets()
    }

    /// Resolve codes to node ids using the chart's identifier index.
    /// Throws if either code is missing.
    public func resolve(in index: RGSIndex
    ) throws -> (ni: (code: String, id: Int), equity: (code: String, id: Int)) {
        guard let niId = index.byIdentifier[netIncomeCode] else {
            throw AutoCloseError.codeNotFound(netIncomeCode)
        }
        guard let eqId = index.byIdentifier[retainedEarningsCode] else {
            throw AutoCloseError.codeNotFound(retainedEarningsCode)
        }
        return ((netIncomeCode, niId), (retainedEarningsCode, eqId))
    }

    /// Optional stricter resolver: also verifies the node kinds using assembler maps.
    /// Expectation: netIncome = .income (W*), retainedEarnings = .balance (B*).
    public func resolve(
        in index: RGSIndex,
        validateWith maps: RGSAssemblerResult
    ) throws -> (ni: (code: String, id: Int), equity: (code: String, id: Int)) {
        let r = try resolve(in: index)
        if let k = maps.kindById[r.ni.id], k != .income {
            throw AutoCloseError.kindMismatch(expected: .income, actual: k, code: r.ni.code)
        }
        if let k = maps.kindById[r.equity.id], k != .balance {
            throw AutoCloseError.kindMismatch(expected: .balance, actual: k, code: r.equity.code)
        }
        return r
    }
}
