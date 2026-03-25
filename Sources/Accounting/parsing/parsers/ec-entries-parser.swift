import Foundation
import plate

public final class EntryCompilerEntriesParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public let defaultTZ: TimeZone
    public init(core: EntryCompilerParserCore, defaultTimeZone: TimeZone) {
        self.core = core
        self.defaultTZ = defaultTimeZone
    }

    public convenience init(
        tokens: [EntryCompilerToken],
        defaultTimeZone: TimeZone,
        fileURL: URL? = nil,
        lineMap: [Int]? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(tokens: tokens, filePath: fileURL?.path, lineMap: lineMap, verbose: verbose),
            defaultTimeZone: defaultTimeZone
        )
    }

    public func parseEntries() throws -> [Entry] {
        var entries: [Entry] = []
        while current != .eof {
            entries.append(try parseEntry(defaultTimeZone: defaultTZ))
        }
        return entries
    }
}
