import Foundation

public struct Account {
    public let id: String
    public let name: String
    public let accountClass: AccountClass
    public let direction: Direction
    public var balance: Double

    public init(
        id: String, 
        name: String, 
        type: AccountClass, 
        direction: Direction, 
        balance: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.accountClass = type
        self.direction = direction
        self.balance = balance
    }
}

public enum BalanceSide: String, CaseIterable, Sendable {
    case left, right
}

public enum AccountClass: String, CaseIterable, Sendable {
    case dividend, expense, asset, liability, equity, revenue, unknown

    public var isPermanent: Bool {
        switch self {
        case .asset, .liability, .equity:
            return true
        case .revenue, .expense, .dividend, .unknown:
            return false
        }
    }

    public var side: BalanceSide {
        switch self {
        case .asset:
            return .left
        case .liability, .equity:
            return .right
        }
    }
}

public struct RGSAccountClassifier: Sendable {
    public static let rekNrBoundaries: [(Int, Int, AccountClass)] = [
        (1000, 2000, .asset), // Immateriële vaste activa
        (2000, 5000, .asset), // Materiële vaste activa
        (5000, 8000, .equity), // Groepsvermogen - Eigen vermogen - Kapitaal
        (8000, 10000, .liability), // Langlopende schulden
        (10000, 13000, .asset), // Liquide middelen
        (13000, 16000, .asset), // Vorderingen
        (16000, 30000, .liability), // Kortlopende schulden
        (30000, 40000, .asset), // Voorraden
        (40000, 80000, .expense), // Lasten uit hoofde van personeelsbeloningen (likely expenses)
        (80000, 90000, .revenue) // Netto-omzet, etc.
    ]

    public static func classForRekNr(_ rekNr: Int) throws -> AccountClass {
        for (start, end, accClass) in rekNrBoundaries {
            if rekNr >= start && rekNr < end {
                return accClass
            }
        }
        throw NSError(domain: "AccountClass", code: 404, userInfo: [NSLocalizedDescriptionKey: "No AccountClass found for rekNr \(rekNr)"])
    }
}
