import Foundation
import Primitives

public typealias UnifiedAccountsPage = ExportPage<UnifiedAccount>

public struct UnifiedAccount: Codable, Sendable, JSONReadable, JSONWritable, Identifiable {
    public enum Orientation: String, Codable, Sendable {
        case regular = "Regular"
        case contra  = "Contra"
    }

    public enum Classification: String, Codable, Sendable {
        case current     = "Current"
        case nonCurrent  = "Non-Current"
    }

    public enum Tangibility: String, Codable, Sendable {
        case tangible   = "Tangible"
        case intangible = "Intangible"
    }

    public let id: Int
    public let name: String
    public let parent: Int
    public let description: String?

    public let orientation: Orientation
    public let classification: Classification?
    public let tangibility: Tangibility?
}

