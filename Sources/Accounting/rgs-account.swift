import Foundation

public struct RGSAccount: Codable {
    public let code: String
    public let label: String
    public let level: Int
    public let direction: Direction?
    public let identifiers: RGSIdentifiers
    public let applicability: Applicability

    public struct RGSIdentifiers: Codable {
        public let rgs: String           // the RGS-code column
        public let omslag: String?       // the Omslagcode column, to flip appearance account based on dr-cr balance
    }

    public struct Applicability: Codable {
        public let zzp: Bool
        public let ez: Bool
        public let bv: Bool
        public let svc: Bool
        public let branche: Bool
    }

    public var parentCode: String? {
        switch level {
            case 1: return nil
            case 2: return String(code.prefix(2)) + "000"
            case 3: return String(code.prefix(3)) + "00"
            case 4: return String(code.prefix(4)) + "0"
            default: return nil
        }
    }
}

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

public func compileBalanceTree(accounts: [RGSAccount], rawBalances: [String: Double]) -> [BalanceNode] {
    // copy raw balances and apply omslag flips
    var balanceByCode = rawBalances
    for acct in accounts {
        let bal = balanceByCode[acct.code] ?? 0
        if let flipTag = acct.identifiers.omslag, bal < 0 {
            balanceByCode[acct.code] = 0
            if let target = accounts.first(where: { $0.identifiers.rgs == flipTag }) {
                balanceByCode[target.code, default: 0] += abs(bal)
            }
        }
    }

    // build nodes
    var nodesByCode: [String: BalanceNode] = [:]
    for acct in accounts {
        let bal = balanceByCode[acct.code] ?? 0
        nodesByCode[acct.code] = BalanceNode(account: acct, balance: bal)
    }

    // attach children bottom-up
    for node in nodesByCode.values.sorted(by: { $0.account.level > $1.account.level }) {
        if let p = node.account.parentCode, let parent = nodesByCode[p] {
            parent.balance += node.balance
            parent.children.append(node)
        }
    }
    // return level-1 roots
    return nodesByCode.values.filter { $0.account.level == 1 }
}
