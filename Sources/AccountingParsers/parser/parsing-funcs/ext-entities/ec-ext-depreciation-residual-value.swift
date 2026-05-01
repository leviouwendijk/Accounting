import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseResidualValue(
        into meta: inout [String:String],
        capturePercentInto outPercent: inout Decimal
    ) throws -> Bool {
        // Accept multiple spellings at the field name level
        let names = ["residual_value","residual","residual_percent","residual_percentage","salvage_value"]
        guard let _ = matchNameToken(names) else { return false }
        advance()

        // Support: residual_value = 300    (amount)
        //          residual_percent = 20   (percent)
        //          residual { percentage = 20 }  (block)
        if current == .equals {
            advance()
            guard case let .number(n) = current else {
                throw ParserError.unexpectedToken(current, expected: "number", at: loc())
            }
            // Heuristic: if the field name contained "percent", treat as percent; else amount
            // (We don't have the matched name here; store both and let later logic decide if needed)
            outPercent = n
            meta["dep.residual.percent"] = "\(n)"
            advance()
            return true
        }

        // Block form
        try expect(.lBrace)
        var sawAnything = false
        while current != .rBrace && current != .eof {
            switch current {
            // allow percent|percentage
            case .ident("percent"), .keyword("percent"),
                 .ident("percentage"), .keyword("percentage"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                outPercent = n
                meta["dep.residual.percent"] = "\(n)"
                advance()
                sawAnything = true

            // allow amount|value (store for later; your current draft only uses percent)
            case .ident("amount"), .keyword("amount"),
                 .ident("value"),  .keyword("value"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                meta["dep.residual.amount"] = "\(n)"
                advance()
                sawAnything = true

            // optional boolean-ish flag you had in older drafts
            case .ident("keep_percentage"), .keyword("keep_percentage"):
                // if you still want this, you can mark a sentinel or just ignore
                advance()
                meta["dep.residual.keep_percentage"] = "true"
                sawAnything = true

            default:
                throw ParserError.unexpectedToken(current, expected: "percentage/percent or amount/value", at: loc())
            }
        }
        try expect(.rBrace)

        if !sawAnything {
            throw ParserError.unexpectedToken(current, expected: "residual_value contents", at: loc())
        }
        return true
    }
}
