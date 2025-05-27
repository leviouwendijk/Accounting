import Foundation

public struct RGSAccount: Codable {
    public let code: String
    public let label: String
    // public let level: Int
    public let direction: Direction?
    public let identifiers: RGSIdentifiers
    public let applicability: Applicability

    public init(
        code: String,
        label: String,
        // level: Int,
        direction: Direction?,
        identifiers: RGSIdentifiers,
        applicability: Applicability
    ) {
        self.code = code
        self.label = label
        // self.level = level
        self.direction = direction
        self.identifiers = identifiers
        self.applicability = applicability
    }

    public var accountClass: AccountClass {
        if label.lowercased().contains("dividend") {
            return .dividend
        }
        switch code.prefix(1) {
        case "0", "1": return .asset
        case "2", "3": return .liability
        case "4":      return .equity
        case "5":      return .revenue
        default:       return .expense
        }
    }

    public var parentCode: String? {
        let trimmed = code.reversed().drop(while: { $0 == "0" })
        guard trimmed.count > 2 else { return nil }
        let nonZeroPart = String(trimmed).reversed()
        let prefixLen = nonZeroPart.count - 1
        let prefix = nonZeroPart.prefix(prefixLen)
        let zeros = String(repeating: "0", count: code.count - prefixLen)
        return String(prefix) + zeros
    }
}

public struct RGSIdentifiers: Codable {
    public let rgs: String           // the RGS-code column
    public let omslag: String?       // the Omslagcode column, to flip appearance account based on dr-cr balance

    public init(
        rgs: String,
        omslag: String?
    ) {
        self.rgs = rgs
        self.omslag = omslag
    }
}

public struct Applicability: Codable {
    public let zzp: Bool
    public let ez: Bool
    public let bv: Bool
    public let svc: Bool
    public let branche: Bool

    public init(
        zzp: Bool,
        ez: Bool,
        bv: Bool,
        svc: Bool,
        branche: Bool
    ) {
        self.zzp = zzp
        self.ez = ez
        self.bv = bv
        self.svc = svc
        self.branche = branche
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
