import Foundation
import plate

public extension LegacyAssetItem {
    @discardableResult
    func writeEC(
        to url: URL,
        className: String = "objects",
        family: String = "usable",
        rootAlias: String? = nil,
        unitAlias: String? = nil,
        depreciationExpenseAccountCode: String? = nil,
        writeOptions: SafeWriteOptions = .init(),
    ) throws -> SafeWriteResult {
        let text = ecString(
            className: className,
            family: family,
            rootAlias: rootAlias,
            unitAlias: unitAlias,
            depreciationExpenseAccountCode: depreciationExpenseAccountCode
        )

        let sf = SafeFile(url)
        let result = try sf.write(text, options: writeOptions)
        return result
    }
}
