import Foundation

public struct EntryCompilerLexingSets: Sendable, Codable {
    public let keywords: Set<String>
    public let idents: Set<String>
    
    public init(
        keywords: Set<String>,
        idents: Set<String>
    ) {
        self.keywords = keywords
        self.idents = idents
    }
}
