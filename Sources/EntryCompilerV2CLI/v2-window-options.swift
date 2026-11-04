import Arguments
import Foundation

struct V2WindowsOptions: ArgumentParsed, Sendable {
    typealias ArgumentPayload = Payload

    let anchor: String
    let unit: String
    let count: Int

    init(arguments: Payload) throws {
        self.anchor = arguments.anchor
        self.unit = arguments.unit
        self.count = arguments.count
    }

    struct Payload: ArgumentGroup {
        @Opt("anchor", default: "2026-10-15")
        var anchor: String

        @Opt("unit", default: "month")
        var unit: String

        @Opt("count", default: 2)
        var count: Int

        init() {}
    }
}
