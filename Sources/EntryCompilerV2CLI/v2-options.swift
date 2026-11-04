import Arguments
import Foundation

struct V2WindowOptions: ArgumentGroup, Sendable {
    @Opt("start", default: "2026-01-01")
    var start: String

    @Opt("end", default: "2027-01-01")
    var end: String

    init() {}
}

struct V2PeriodOptions: ArgumentParsed, Sendable {
    typealias ArgumentPayload = Payload

    let window: V2WindowOptions
    let byEntity: Bool

    init(arguments: Payload) throws {
        self.window = arguments.window
        self.byEntity = arguments.byEntity
    }

    struct Payload: ArgumentGroup {
        @Group("window")
        var window: V2WindowOptions

        @Flag("by-entity")
        var byEntity: Bool

        init() {}
    }
}

struct V2CompileOptions: ArgumentParsed, Sendable {
    typealias ArgumentPayload = Payload

    let window: V2WindowOptions
    let closing: Bool
    let carryforward: Bool
    let byEntity: Bool
    let trace: Bool

    init(arguments: Payload) throws {
        self.window = arguments.window
        self.closing = arguments.closing
        self.carryforward = arguments.carryforward
        self.byEntity = arguments.byEntity
        self.trace = arguments.trace
    }

    struct Payload: ArgumentGroup {
        @Group("window")
        var window: V2WindowOptions

        @Flag("closing")
        var closing: Bool

        @Flag("carryforward")
        var carryforward: Bool

        @Flag("by-entity")
        var byEntity: Bool

        @Flag("trace")
        var trace: Bool

        init() {}
    }
}
