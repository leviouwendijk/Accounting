import Foundation
import Accounting

public final class EntryCompilerTransactionsFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    private let fileURL: URL?

    public init(core: EntryCompilerParserCore, fileURL: URL? = nil) {
        self.core = core
        self.fileURL = fileURL
    }
    public convenience init(
        tokens: [EntryCompilerToken],
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
            fileURL: fileURL
        )
    }

    public func parseTransactionsFile() throws -> [Transaction] {
        core.trace("parsing transactions file: \(fileURL?.lastPathComponent ?? "<memory>")")
        var out: [Transaction] = []
        while current != .eof {
            core.trace("• transaction block @ \(loc())")
            out.append(try parseTransactionBlock())
        }
        return out
    }
}
