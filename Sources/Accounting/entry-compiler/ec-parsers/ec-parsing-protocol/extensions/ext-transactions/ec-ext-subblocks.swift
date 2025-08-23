import Foundation

public extension EntryCompilerParsing {
    // transaction { ... }
    // --- helpers ---

    /// Accepts:
    ///   date = 2025-08-21
    ///   date { year=2025 month=08 day=21 }
    ///   date infer 15
    @inlinable
    func parseTransactionDateDirective() throws -> DateSpecification {
        try parseDateOrInfer(tz: .current, allowUnixEpoch: false)
    }

    @inlinable
    func parseTransactionIdentifiersBlock() throws -> TransactionIdentifiers {
        try expect(.keyword("identifiers"))
        try beginBlock()
        var out = TransactionIdentifiers()
        while current != .rBrace && current != .eof {
            switch current {
            case .ident("platform_account_id"):
                try expectFieldEquals("platform_account_id")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                out.platformAccountID = (n as NSDecimalNumber).intValue
                advance()

            case .ident("platform_transaction_id"):
                try expectFieldEquals("platform_transaction_id")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                out.platformTransactionID = (n as NSDecimalNumber).intValue
                advance()

            default:
                throw ParserError.unexpectedToken(current, expected: "platform_account_id/platform_transaction_id", at: loc())
            }
        }
        try endBlock()
        return out
    }

    @inlinable
    func parseTransactionAmountBlock() throws -> TransactionAmount {
        try expect(.keyword("amount")) 
        try beginBlock()
        var currency: String?
        var gross: Decimal?
        var fee: Decimal?
        var net: Decimal?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("currency"):
                try expectFieldEquals("currency")
                if case let .keyword(s) = current { currency = s; advance() }
                else if case let .string(s) = current { currency = s; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc()) }

            case .keyword("gross"):
                try expectFieldEquals("gross")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                gross = n; advance()

            case .keyword("fee"):
                try expectFieldEquals("fee")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                fee = n; advance()

            case .keyword("net"):
                try expectFieldEquals("net")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                net = n; advance()

            default:
                throw ParserError.unexpectedToken(current, expected: "currency/gross[/fee][/net]", at: loc())
            }
        }

        try endBlock()
        guard let c = currency, let g = gross else {
            throw ParserError.unexpectedToken(current, expected: "currency and gross", at: loc())
        }
        return TransactionAmount(currency: c, gross: g, fee: fee, net: net)
    }

    @inlinable
    func parseTransactionCounterpartyBlock() throws -> TransactionCounterparty {
        try expect(.keyword("counterparty")); try beginBlock()
        var name: String?
        var iban: String?
        var bic: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("name"):
                try expectFieldEquals("name")
                if case let .string(s) = current { name = s; advance() }
                else if case let .keyword(s) = current { name = s; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc()) }

            case .keyword("iban"):
                try expectFieldEquals("iban")
                if case let .string(s) = current { iban = s; advance() }
                else if case let .keyword(s) = current { iban = s; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc()) }

            case .keyword("bic"):
                try expectFieldEquals("bic")
                if case let .string(s) = current { bic = s; advance() }
                else if case let .keyword(s) = current { bic = s; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc()) }

            default:
                throw ParserError.unexpectedToken(current, expected: "name/iban/bic", at: loc())
            }
        }

        try endBlock()
        return TransactionCounterparty(name: name, iban: iban, bic: bic)
    }

    // /// details { "quoted ok" } OR details { free tokens until '}' }
    // @inlinable
    // func parseFreeTextBlock() throws -> String {
    //     try expect(.ident("details")); try beginBlock()
    //     var parts: [String] = []
    //     while current != .rBrace && current != .eof {
    //         switch current {
    //         case let .string(s): parts.append(s); advance()
    //         case let .ident(s):  parts.append(s); advance()
    //         case let .number(n): parts.append("\(n)"); advance()
    //         default: break
    //         }
    //     }
    //     try endBlock()
    //     return parts.joined(separator: " ")
    // }

    // /// metadata { key = "value"  other=foo }
    // @inlinable
    // func parseStringMapBlock() throws -> [String:String] {
    //     try expect(.ident("metadata")); try beginBlock()
    //     var out: [String:String] = [:]
    //     while current != .rBrace && current != .eof {
    //         guard case let .ident(k) = current else {
    //             throw ParserError.unexpectedToken(current, expected: "identifier (key)", at: loc())
    //         }
    //         advance(); try expect(.equals)
    //         if case let .string(v) = current { out[k] = v; advance() }
    //         else if case let .ident(v) = current { out[k] = v; advance() }
    //         else if case let .number(n) = current { out[k] = "\(n)"; advance() }
    //         else {
    //             throw ParserError.unexpectedToken(current, expected: "string|identifier|number", at: loc())
    //         }
    //     }
    //     try endBlock()
    //     return out
    // }
}
