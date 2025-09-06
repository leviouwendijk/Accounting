import Foundation

public struct OwnerDelta {
    public let stort: Decimal
    public let onttrek: Decimal
    public let winst: Decimal
    public var delta: Decimal { stort - onttrek + winst }
    public init(stort: Decimal, onttrek: Decimal, winst: Decimal) {
        self.stort = stort; self.onttrek = onttrek; self.winst = winst
    }
}
