import Accounting
import Foundation
import TestFlows

extension AccountingTestFlowsSuite {
    static var accountingStructuralIdentitiesFlow: TestFlow {
        TestFlow("accounting-structural-identities", tags: ["accounting", "invariance"]) {
            Step("account key validates intrinsic nonempty code without canonicalization") {
                let code = try AccountKey("00042")
                try Expect.equal(code.code, "00042", "leading zeros preserved")
                try Expect.throwsError("empty code") { _ = try AccountKey("") }
                try Expect.throwsError("whitespace-only code") { _ = try AccountKey("  ") }
            }
            Step("account path validates components") {
                let path = try AccountPath(segments: ["assets", "cash"])
                try Expect.equal(path.segments, ["assets", "cash"], "stable components")
                for segments in [[], [""], ["assets", ""], ["assets.cash"], ["   "]] {
                    try Expect.throwsError("invalid path segments: \(segments)") {
                        _ = try AccountPath(segments: segments)
                    }
                }
            }
            Step("decode cannot bypass account structural invariants") {
                let decoder = JSONDecoder()
                try Expect.throwsError("invalid decoded code") {
                    _ = try decoder.decode(AccountKey.self, from: Data(#"{"code":""}"#.utf8))
                }
                try Expect.throwsError("invalid decoded path") {
                    _ = try decoder.decode(AccountPath.self, from: Data(#"{"segments":["assets",""]}"#.utf8))
                }
                let restored = try decoder.decode(AccountKey.self, from: Data(#"{"code":"00042"}"#.utf8))
                try Expect.equal(restored.code, "00042", "keyed encoding schema preserved")
            }
        }
    }
}
