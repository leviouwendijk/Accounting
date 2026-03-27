import Foundation

public final class EntryCompilerEntitiesFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public let defaultTZ: TimeZone
    private let fileURL: URL?

    public init(
        core: EntryCompilerParserCore,
        defaultTZ: TimeZone,
        fileURL: URL? = nil
    ) {
        self.core = core
        self.fileURL = fileURL
        self.defaultTZ = defaultTZ
    }

    public convenience init(
        tokens: [EntryCompilerToken],
        defaultTZ: TimeZone,
        fileURL: URL? = nil,
        lineMap: [Int]? = nil,
        spanMap: [SourceSpan]? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(
                tokens: tokens,
                filePath: fileURL?.path,
                lineMap: lineMap,        
                spanMap: spanMap,
                verbose: verbose
            ), 
            defaultTZ: defaultTZ,
            fileURL: fileURL
        )
    }

    public func parseEntitiesFile() throws -> [EntityDef] {
        core.trace("parsing entities file: \(fileURL?.lastPathComponent ?? "<memory>")")
        var out: [EntityDef] = []
        while current != .eof {
            let before = core.index
            if current == .keyword("entity") {
                core.trace("• entity block @ \(loc())")
                let defs = try parseEntityBlock(fileURL: fileURL, defaultTZ: defaultTZ)   // returns [EntityDef]
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
