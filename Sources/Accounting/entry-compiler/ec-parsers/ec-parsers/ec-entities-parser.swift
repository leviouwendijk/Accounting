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

    public convenience init(tokens: [EntryCompilerToken], fileURL: URL? = nil, verbose: Bool = false) {
        self.init(core: .init(tokens: tokens, filePath: fileURL?.path, verbose: verbose), fileURL: fileURL)
    }

    // public func parseEntitiesFile() throws -> [EntityDef] {
    //     var out: [EntityDef] = []
    //     while current != .eof {
    //         if current == .keyword("entity") {
    //             out.append(contentsOf: try parseEntityBlock(fileURL: fileURL))
    //         } else {
    //             advance()
    //         }
    //     }
    //     return out
    // }

    public func parseEntitiesFile() throws -> [EntityDef] {
        core.trace("parsing entities file: \(fileURL?.lastPathComponent ?? "<memory>")")
        var out: [EntityDef] = []
        while current != .eof {
            let before = core.index
            if current == .keyword("entity") {
                core.trace("• entity block @ \(loc())")
                let defs = try parseEntityBlock(fileURL: fileURL)   // returns [EntityDef]
                if let last = defs.last {
                    core.trace("  → produced \(defs.count) def(s), last=\(last.key.identifier(displaying: .fullchain))")
                } else {
                    core.trace("  → produced 0 def(s)")
                }
                out.append(contentsOf: defs)
            } else {
                advance()
            }
            // stall guard (if nothing advanced, bail with a helpful error)
            if core.index == before {
                throw ParserError.unexpectedToken(current, expected: "parser progress", at: loc())
            }
        }
        return out
    }
}
