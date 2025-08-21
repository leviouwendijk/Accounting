import Foundation

public final class EntryCompilerSettingsParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public init(core: EntryCompilerParserCore) { self.core = core }
    public convenience init(tokens: [EntryCompilerToken]) {
        self.init(core: EntryCompilerParserCore(tokens: tokens))
    }
}
