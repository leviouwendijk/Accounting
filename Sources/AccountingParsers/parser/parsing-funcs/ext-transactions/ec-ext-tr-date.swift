import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseTransactionDateDirective() throws -> DateSpecification {
        try parseDateOrInfer(tz: .current, allowUnixEpoch: false)
    }
}
