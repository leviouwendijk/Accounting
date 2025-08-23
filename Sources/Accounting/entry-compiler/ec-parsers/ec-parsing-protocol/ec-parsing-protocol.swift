import Foundation

public protocol EntryCompilerParsing: AnyObject {
    var core: EntryCompilerParserCore { get set }
    var current: EntryCompilerToken { get }
    func loc() -> SourceLocation
}

public extension EntryCompilerParsing {
    @inlinable
    func withCallSite<T>(_ site: InvocationCallSite, _ body: () throws -> T) rethrows -> T {
        // copy–modify–writeback because `core` is a struct behind a protocol property
        var c = core
        c.pushCallSite(site)
        self.core = c
        defer {
            var c2 = core
            c2.popCallSite()
            self.core = c2
        }
        return try body()
    }
}
