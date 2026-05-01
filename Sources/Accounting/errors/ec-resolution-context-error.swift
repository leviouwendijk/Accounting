import Foundation
import Position

public struct ResolutionContextError: Error, CustomStringConvertible, Sendable {
    public let entryID: Int?
    public let location: Position?
    public let underlying: Error

    public init(entryID: Int?, location: Position?, underlying: Error) {
        self.entryID = entryID
        self.location = location
        self.underlying = underlying
    }

    public var description: String {
        var s = String(describing: underlying)
        if let id = entryID { s += " [entry \(id)]" }
        if let loc = location { s += " @ \(loc)" }
        return s
    }
}
