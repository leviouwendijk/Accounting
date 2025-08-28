import Foundation

public struct EntityDef: Sendable, Codable {
    public let key: EntityKey
    public var displayName: String?
    public var metadata: [String:String]
    public var depreciation: DepreciationConfig?
    
    public init(
        key: EntityKey,
        displayName: String?,
        metadata: [String:String],
        depreciation: DepreciationConfig?
    ) {
        self.key = key
        self.displayName = displayName
        self.metadata = metadata
        self.depreciation = depreciation
    }
}
