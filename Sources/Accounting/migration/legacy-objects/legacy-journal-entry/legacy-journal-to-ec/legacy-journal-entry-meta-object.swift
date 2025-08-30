import Foundation

internal struct MetaObject {
    internal let key: String
    internal let value: String
    
    public init(
        _ key: String,
        _ value: String
    ) {
        self.key = key
        self.value = value
    }
}
