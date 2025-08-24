import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseTransactionDateDirective() throws -> DateSpecification {
        try parseDateOrInfer(tz: .current, allowUnixEpoch: false)
    }
}
