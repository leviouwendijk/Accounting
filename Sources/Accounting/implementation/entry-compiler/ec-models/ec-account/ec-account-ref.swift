import Foundation

public enum AccountRef: Hashable, Codable, Sendable {
    case identifier(String)    // "BIvaKooVvpInv" (new fast-path)
    case code(String)          // "10201"
    case path([String])        // dotted/arrow path (legacy sugar) / newer localized chart implementation
}

public extension AccountRef {
    var debugString: String { "\(self)" }
}
