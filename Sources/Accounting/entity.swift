import Foundation

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
