import Accounting
import Foundation

extension TaxonomyTester {
    public static func stderrPrint(
        _ value: String
    ) {
        FileHandle.standardError.write(Data(value.utf8))
        FileHandle.standardError.write(Data("\n".utf8))
    }
}
