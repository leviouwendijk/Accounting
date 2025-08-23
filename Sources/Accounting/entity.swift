import Foundation

// (!): FILE NOT USED BY NEW ENTRY COMPILER

// BACKWARDS COMPAT
public struct Entity {
    public let id: String
    public let name: String
    public let category: EntityType

    public init(id: String, name: String, category: EntityType) {
        self.id = id
        self.name = name
        self.category = category
    }
}

public enum EntityType: String {
    case person, group, company, object, money
}


// NEW VERSION:
public enum EntityIdentifier: Codable, Sendable {
    case liquids(Liquids)
    case people(People)
    case objects(Objects)
    case processes(Processes)
    case products(Products)
}

public enum Liquids: Codable, Sendable {
    case notes
    case stock
    case money(Money)

    public enum Money: String, Codable, Sendable {
        case main
        case vat
        case other
    }
}

public enum People: Codable, Sendable {
    case employees
    case owners(Owners)

    public enum Owners: String, Codable, Sendable {
        case levi
        case casper
        case shoshana
    }
}

public enum Objects: Codable, Sendable {
    case usable(Usable)
    case inventory(Inventory)
    case consumables(Consumable)

    public enum Usable: String, Codable, Sendable {
        case honda_crv = "vehicle_a"
        case macbook_levi = "macbook_b"
    }
    public enum Inventory: String, Codable, Sendable {
        case o_rings
    }
    public enum Consumable: String, Codable, Sendable {
        case fuel
    }
}

public enum Processes: Codable, Sendable {
    case deliverable(Deliverable)
    case purchasables

    public enum Deliverable: String, Codable, Sendable {
        case session
    }
}

public enum Products: Codable, Sendable {
    case physical(Physical)
    case digital(Digital)

    public enum Physical: String, Codable, Sendable {
        case placeholder
        // add concrete SKUs later
    }

    public enum Digital: String, Codable, Sendable {
        case placeholder
        // add concrete SKUs later
    }
}
