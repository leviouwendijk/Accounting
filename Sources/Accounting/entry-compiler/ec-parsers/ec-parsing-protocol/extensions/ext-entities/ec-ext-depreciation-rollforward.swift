import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseDepreciationRollforward(into meta: inout [String:String], tz: TimeZone = .current) throws -> Bool {
        guard current == .ident("rollforward") || current == .keyword("rollforward") else { return false }
        advance(); try expect(.lBrace)
        var idx = 0

        func parseEvent(kind: String) throws {
            advance(); try expect(.lBrace)

            var dateStr: String?
            var amount: String?
            var linked: [Int] = []
            var reason: String?

            var residualValueKeep = false
            var residualValuePct: String?
            var residualValueAmt: String?

            while current != .rBrace && current != .eof {
                switch current {

                case .keyword("effective_date"), .ident("effective_date"):
                    advance(); try expect(.equals)
                    if case let .dateLiteral(text) = current {
                        let d = try parseDateLiteral(text, in: tz)
                        dateStr = ISO8601DateFormatter().string(from: d)
                        advance()
                    } else if current == .lBrace {
                        let d = try parseDateBlock(tz: tz)
                        dateStr = ISO8601DateFormatter().string(from: d)
                    } else {
                        throw ParserError.unexpectedToken(current, expected: "date literal or {…} date block", at: loc())
                    }

                case .keyword("amount"), .ident("amount"), .keyword("value"), .ident("value"):
                    advance(); try expect(.equals)
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                    }
                    amount = "\(n)"; advance()

                case .keyword("linked_entry"), .ident("linked_entry"),
                     .keyword("linked_entries"), .ident("linked_entries"):
                    advance(); try expect(.equals)
                    linked.removeAll()
                    if current == .lBrace {
                        advance()
                        try parseIntList(into: &linked)
                        try expect(.rBrace)
                    } else {
                        try parseIntList(into: &linked)
                    }

                case .keyword("details"), .ident("details"),
                     .keyword("reason"),  .ident("reason"):
                    reason = try parseFreeTextBlock(named: "details")

                case .keyword("revised_useful_life"), .ident("revised_useful_life"):
                    advance(); try expect(.equals)
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                    }
                    meta["dep.rollforward.\(idx).revised_useful_life"] = "\(n)"; advance()

                case .keyword("method"), .ident("method"):
                    advance(); try expect(.equals)
                    switch current {
                    case let .ident(m), let .keyword(m):
                        meta["dep.rollforward.\(idx).method"] = m; advance()
                    default:
                        throw ParserError.unexpectedToken(current, expected: "depreciation method", at: loc())
                    }

                case .keyword("residual_value"), .ident("residual_value"):
                    advance(); try expect(.lBrace)
                    while current != .rBrace && current != .eof {
                        switch current {
                        case .keyword("keep_percentage"), .ident("keep_percentage"):
                            residualValueKeep = true; advance()
                        case .keyword("percentage"), .ident("percentage"):
                            advance(); try expect(.equals)
                            guard case let .number(n) = current else {
                                throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                            }
                            residualValuePct = "\(n)"; advance()
                        case .keyword("amount"), .ident("amount"), .keyword("value"), .ident("value"):
                            advance(); try expect(.equals)
                            guard case let .number(n) = current else {
                                throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                            }
                            residualValueAmt = "\(n)"; advance()
                        default:
                            throw ParserError.unexpectedToken(current, expected: "keep_percentage|percentage|amount|value or '}'", at: loc())
                        }
                    }
                    try expect(.rBrace)

                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "effective_date/amount|value/linked_entry(s)/details|reason|method|revised_useful_life|residual_value or '}'",
                        at: loc()
                    )
                }
            }

            try expect(.rBrace)

            if residualValueKeep { meta["dep.rollforward.\(idx).residual.keep"] = "true" }
            if let p = residualValuePct { meta["dep.rollforward.\(idx).residual.pct"] = p }
            if let a = residualValueAmt { meta["dep.rollforward.\(idx).residual.amount"] = a }
            if let d = dateStr { meta["dep.rollforward.\(idx).date"] = d }
            if let a = amount { meta["dep.rollforward.\(idx).amount"] = a }
            if !linked.isEmpty { meta["dep.rollforward.\(idx).linked"] = linked.map(String.init).joined(separator: ",") }
            if let r = reason { meta["dep.rollforward.\(idx).reason"] = r }
            meta["dep.rollforward.\(idx).kind"] = kind
            idx += 1
        }

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("capex"), .ident("capex"):       try parseEvent(kind: "capex")
            case .keyword("revision"), .ident("revision"): try parseEvent(kind: "revision")
            default:
                throw ParserError.unexpectedToken(current, expected: "capex or revision", at: loc())
            }
        }
        try expect(.rBrace)
        return true
    }

    @inlinable
    func parseDepreciationValuation(into meta: inout [String:String]) throws -> Bool {
        guard current == .keyword("valuation") || current == .ident("valuation") else { return false }
        advance(); try expect(.lBrace)
        while current != .rBrace && current != .eof {
            guard current == .keyword("acquisition_cost") || current == .ident("acquisition_cost") else {
                throw ParserError.unexpectedToken(current, expected: "acquisition_cost or '}'", at: loc())
            }
            advance(); try expect(.lBrace)
            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("direct"), .ident("direct"):
                    advance(); try expect(.equals)
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                    }
                    meta["dep.valuation.acquisition.direct"] = "\(n)"; advance()
                case .keyword("indirect"), .ident("indirect"):
                    advance(); try expect(.equals)
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                    }
                    meta["dep.valuation.acquisition.indirect"] = "\(n)"; advance()
                default:
                    throw ParserError.unexpectedToken(current, expected: "direct|indirect or '}'", at: loc())
                }
            }
            try expect(.rBrace)
        }
        try expect(.rBrace)
        return true
    }

    @inlinable
    func parseUsefulLifeMonths(into meta: inout [String:String]) throws -> Bool {
        guard current == .keyword("useful_life_months") || current == .ident("useful_life_months") else { return false }
        advance(); try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        meta["dep.useful_life_months"] = "\(n)"
        advance()
        return true
    }
}
