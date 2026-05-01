import Accounting
import AccountingCompiler
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var entryCoreFlow: TestFlow {
        TestFlow(
            "accounting-entry-core",
            tags: [
                "accounting",
                "entries",
                "trial-balance",
                "core",
            ]
        ) {
            Step("resolved entries balance and produce trial balance rows") {
                let entity = EntityKey(
                    class: "owner",
                    family: "capital",
                    alias: EntityAlias.parse("levi")
                )

                let entry = ResolvedEntry(
                    id: 1,
                    date: .absolute(Date(timeIntervalSince1970: 0)),
                    lines: [
                        ResolvedLine(
                            entity: entity,
                            account: AccountKey("BLimBanRba"),
                            direction: .debit,
                            amount: 100,
                            adjustment: nil
                        ),
                        ResolvedLine(
                            entity: entity,
                            account: AccountKey("BEivKapOndAow"),
                            direction: .credit,
                            amount: 100,
                            adjustment: nil
                        ),
                    ],
                    details: "Opening capital",
                    timezone: nil,
                    metadata: [:],
                    transactionReferences: []
                )

                try entry.assertBalancing()

                let rows = trialBalance([entry])
                let byCode = Dictionary(
                    uniqueKeysWithValues: rows.map { ($0.accountCode, $0) }
                )

                try Expect.equal(
                    rows.count,
                    2,
                    "trial-balance.row-count"
                )

                try Expect.equal(
                    byCode["BLimBanRba"]?.debit,
                    100,
                    "trial-balance.bank.debit"
                )

                try Expect.equal(
                    byCode["BLimBanRba"]?.credit,
                    0,
                    "trial-balance.bank.credit"
                )

                try Expect.equal(
                    byCode["BEivKapOndAow"]?.debit,
                    0,
                    "trial-balance.equity.debit"
                )

                try Expect.equal(
                    byCode["BEivKapOndAow"]?.credit,
                    100,
                    "trial-balance.equity.credit"
                )
            }
        }
    }
}
