import Foundation

public struct LedgerBucket: Sendable {
    public var debit: Decimal = 0
    public var credit: Decimal = 0

    @inlinable 
    public var net: Decimal { 
        debit - credit 
    }

    @inlinable 
    public mutating func add(dir: Direction, amount: Decimal) {
        if dir == .debit { debit += amount } else { credit += amount }
    }
}
