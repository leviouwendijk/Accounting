import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseTransactionCounterpartyBlock() throws -> TransactionCounterparty {
        try expect(.keyword("counterparty")); try beginBlock()
        var name: String?
        var iban: String?
        var bic: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("name"), .keyword("name"):
                try expectFieldEquals("name")
                if current == .lBrace {
                    name = try readVerbatimBlockBody()     // name { ACME B.V. }
                } else {
                    name = readUnquotedValueUntilPairOrBlockEnd() // name = ACME B.V.
                }

            case .ident("iban"), .keyword("iban"):
                try expectFieldEquals("iban")
                switch current {
                case let .string(s), let .ident(s), let .keyword(s): iban = s; advance()
                default: throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc())
                }

            case .ident("bic"), .keyword("bic"):
                try expectFieldEquals("bic")
                switch current {
                case let .string(s), let .ident(s), let .keyword(s): bic = s; advance()
                default: throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc())
                }

            default:
                throw ParserError.unexpectedToken(current, expected: "name/iban/bic", at: loc())
            }
        }

        try endBlock()
        return TransactionCounterparty(name: name, iban: iban, bic: bic)
    }
}
