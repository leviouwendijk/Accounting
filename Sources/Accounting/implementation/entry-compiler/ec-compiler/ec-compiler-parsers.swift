import Foundation
import plate

public struct EntryCompilerParsers: Sendable {
    public let makeSettings: @Sendable (_ root: URL) throws -> EntryCompilerSettings
    public let makeEntries:  @Sendable (_ tokens: [EntryCompilerToken], _ defaultTZ: TimeZone) -> EntryCompilerEntriesParser

    public init(
        makeSettings: @Sendable @escaping (_ root: URL) throws -> EntryCompilerSettings,
        makeEntries: @Sendable @escaping (_ tokens: [EntryCompilerToken], _ defaultTZ: TimeZone) -> EntryCompilerEntriesParser
    ) {
        self.makeSettings = makeSettings
        self.makeEntries  = makeEntries
    }

    public static var `default`: EntryCompilerParsers {
        .init(
            makeSettings: { try EntryCompilerSettingsLoader.load(from: $0) },
            makeEntries:  { tokens, tz in EntryCompilerEntriesParser(tokens: tokens, defaultTimeZone: tz) }
        )
    }
}
