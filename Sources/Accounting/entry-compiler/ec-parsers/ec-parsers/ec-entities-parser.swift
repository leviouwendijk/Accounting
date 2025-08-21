import Foundation

public final class EntryCompilerEntitiesFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public init(core: EntryCompilerParserCore) { self.core = core }
    public convenience init(tokens: [EntryCompilerToken]) { self.init(core: .init(tokens: tokens)) }

    /// Parse one entities file: `entity { ... }` blocks, using optional path inference.
    public func parseEntitiesFile(inferredClass: String?, inferredFamily: String?) throws -> [EntityDef] {
        var out: [EntityDef] = []
        while current != .eof {
            out.append(try parseEntityBlock(inferredClass: inferredClass, inferredFamily: inferredFamily))
        }
        return out
    }
}
