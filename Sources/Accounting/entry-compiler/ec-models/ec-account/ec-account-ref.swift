import Foundation

public enum AccountRef: Hashable, Codable, Sendable {
    case code(String)          // "10201"
    case path([String])        // dotted/arrow path (legacy sugar)
}
