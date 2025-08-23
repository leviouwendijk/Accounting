import Foundation

// Parse a file of one or more `transaction { ... }` blocks.
public final class EntryCompilerTransactionsFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public init(core: EntryCompilerParserCore) { self.core = core }
    public convenience init(tokens: [EntryCompilerToken]) { self.init(core: .init(tokens: tokens)) }

    public func parseTransactionsFile() throws -> [Transaction] {
        var out: [Transaction] = []
        while current != .eof {
            out.append(try parseTransactionBlock())
        }
        return out
    }
}
