import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseTransactionIdentifiersBlock() throws -> TransactionIdentifiers {
        try expect(.keyword("identifiers")) 
        try beginBlock()
        var out = TransactionIdentifiers()
        while current != .rBrace && current != .eof {
            switch current {
            case .ident("platform_account_id"), .keyword("platform_account_id"):
                try expectFieldEquals("platform_account_id")
                out.platformAccountID = try expectInteger()

            case .ident("platform_transaction_id"), .keyword("platform_transaction_id"):
                try expectFieldEquals("platform_transaction_id")
                out.platformTransactionID = try expectInteger()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "platform_account_id/platform_transaction_id",
                    at: loc()
                )
            }
        }
        try endBlock()
        return out
    }
}
