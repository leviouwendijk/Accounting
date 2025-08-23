import Foundation

// public final class EntryCompilerEntitiesFileParser: EntryCompilerParsing {
//     public var core: EntryCompilerParserCore
//     public init(core: EntryCompilerParserCore) { self.core = core }
//     public convenience init(tokens: [EntryCompilerToken]) { self.init(core: .init(tokens: tokens)) }

//     /// Parse one entities file: `entity { ... }` blocks, using optional path inference.
//     public func parseEntitiesFile(inferredClass: String?, inferredFamily: String?) throws -> [EntityDef] {
//         var out: [EntityDef] = []
//         while current != .eof {
//             out.append(try parseEntityBlock(inferredClass: inferredClass, inferredFamily: inferredFamily))
//         }
//         return out
//     }
// }

public final class EntryCompilerEntitiesFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    private let fileURL: URL?

    public init(core: EntryCompilerParserCore, fileURL: URL? = nil) {
        self.core = core
        self.fileURL = fileURL
    }
    public convenience init(tokens: [EntryCompilerToken], fileURL: URL? = nil) {
        self.init(core: .init(tokens: tokens), fileURL: fileURL)
    }

    public func parseEntitiesFile() throws -> [EntityDef] {
        var out: [EntityDef] = []
        while current != .eof {
            if current == .keyword("entity") {
                out.append(try parseEntityBlock(fileURL: fileURL)) // uses inferClassFamily(fileURL)
            } else {
                advance()
            }
        }
        return out
    }
}
