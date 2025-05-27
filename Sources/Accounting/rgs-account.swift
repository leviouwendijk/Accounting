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
        let numeric: Int = {
            if code.count >= 5 {
                return Int(code.prefix(5)) ?? 0
            } else {
                return Int(code) ?? 0
            }
        }()

        do {
            let classification = try RGSAccountClassifier.classForRekNr(numeric)
            let str = "[\(classification)]: ".uppercased() + code + " -- " + label 
            print(str)
            return classification
            // return try RGSAccountClassifier.classForRekNr(numeric)
        } catch {
            // Option 1: fallback to unknown (recommended)
            return .unknown
            // Option 2: crash (not recommended)
            // fatalError(error.localizedDescription)
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
