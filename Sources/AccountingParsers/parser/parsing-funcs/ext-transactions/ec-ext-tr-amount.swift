import Foundation
import Accounting

public extension EntryCompilerParsing {
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
            case .ident("currency"), .keyword("currency"):
                try expectFieldEquals("currency")
                switch current {
                case let .ident(s), let .keyword(s), let .string(s): currency = s; advance()
                    default: 
                        throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }

            case .ident("gross"), .keyword("gross"):
                try expectFieldEquals("gross")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                gross = n; advance()

            case .ident("fee"), .keyword("fee"):
                try expectFieldEquals("fee")
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                fee = n; advance()

            case .ident("net"), .keyword("net"):
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
}
