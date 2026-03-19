import Foundation

public class BalanceNode {
    public let account: RGSAccount
    public var balance: Double
    public var children: [BalanceNode] = []

    public init(
        account: RGSAccount, 
        balance: Double
    ) {
        self.account = account
        self.balance = balance
    }
}

public func compileBalanceTree(
    accounts: [RGSAccount],
    rawBalances: [String: Double]
) -> [BalanceNode] {
    // copy raw balances and apply omslag flips
    var balanceByCode = rawBalances
    for acct in accounts {
        let bal = balanceByCode[acct.code] ?? 0
        if let flipTag = acct.identifiers.omslag, bal < 0,
           let target = accounts.first(where: { $0.identifiers.rgs == flipTag }) {
            balanceByCode[acct.code] = 0
            balanceByCode[target.code, default: 0] += abs(bal)
        }
    }

    // build a node for every account
    var nodesByCode: [String: BalanceNode] = [:]
    for acct in accounts {
        let bal = balanceByCode[acct.code] ?? 0
        nodesByCode[acct.code] = BalanceNode(account: acct, balance: bal)
    }

    // attach children to parents bottom-up.
    //    sort by code length descending so deeper nodes get attached first.
    for node in nodesByCode.values
    .sorted(by: { $0.account.code.count > $1.account.code.count }) {
        if let pcode = node.account.parentCode, let parent = nodesByCode[pcode] {
            parent.balance += node.balance
            parent.children.append(node)
        }
    }

    // roots are those with no parent
    return nodesByCode.values
    .filter { $0.account.parentCode == nil }
}
