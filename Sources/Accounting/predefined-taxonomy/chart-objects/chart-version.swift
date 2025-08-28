import Foundation
import plate

public struct ChartVersion: Sendable, Codable {
    public let major: Int
    public let minor: Int
    
    public init(
        major: Int,
        minor: Int
    ) {
        self.major = major
        self.minor = minor
    }

    public func string(separator: String) -> String {
        return "\(major)\(separator)\(minor)"
    }

    public func versionString(separator: String) -> String {
        return "v" + string(separator: separator)
    }

    public func filename(
        version: Bool,
        separator: String,
        ext: DocumentExtensionType
    ) -> String {
        var name = ""

        switch version {
            case true:
                name = versionString(separator: separator)
            case false:
                name = string(separator: separator)
        }

        return name + ext.dotPrefixed
    }
}
