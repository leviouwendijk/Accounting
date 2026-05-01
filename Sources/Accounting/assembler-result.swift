import Foundation

public struct RGSAssemblerResult: Sendable {
    public let totalsById: [Int: Decimal]
    public let kindById: [Int: StatementKind]
    public let sortKeyById: [Int: String]        // id -> "A.B.A010"
    public let directionById: [Int: Direction]
    public let parentById: [Int: Int]            // (still kept for debugging)
    public let keyToId: [String: Int]            // "A.B.A010" -> id   NEW
    public let nameById: [Int: String]           // node.labels.short   NEW
    
    public init(
        totalsById: [Int: Decimal],
        kindById: [Int: StatementKind],
        sortKeyById: [Int: String],
        directionById: [Int: Direction],
        parentById: [Int: Int],
        keyToId: [String: Int],
        nameById: [Int: String]
    ) {
        self.totalsById = totalsById
        self.kindById = kindById
        self.sortKeyById = sortKeyById
        self.directionById = directionById
        self.parentById = parentById
        self.keyToId = keyToId
        self.nameById = nameById
    }
}

