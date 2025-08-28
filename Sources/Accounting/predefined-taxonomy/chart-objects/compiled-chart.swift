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

public struct CompiledChart: Sendable, Codable {
    public let name: String                    // "RGS-DutchGAAP-2025 (v3.8)"
    public let version: ChartVersion           // 3.8
    public let nodes: [RGSNode]                // leaf + intermediate + whatever you want (even just leaves)
    public let index: RGSIndex
}

public struct Account: Sendable, Codable, Hashable {
    public let id: Int
    public let gl: String
    public let name: String
    public let rgsIdentifier: String           // store string; resolve to id once on load
}
