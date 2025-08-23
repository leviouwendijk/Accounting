import Foundation

public extension EntryCompilerParsing {
    // transaction { ... }
    @inlinable
    func parseTransactionBlock() throws -> Transaction {
        try expectKeyword("transaction")
        try beginBlock()

        var id: Int?
        var dateSpec: DateSpecification?
        var source: TransactionSource?
        var identifiers = TransactionIdentifiers()
        var amount: TransactionAmount?
        var details: String?
        var counterparty: TransactionCounterparty?
        var metadata: [String:String] = [:]
        var status: TransactionStatus?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("id"):
                try expectFieldEquals("id")
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                id = (n as NSDecimalNumber).intValue
                advance()

            case .keyword("date"):
                dateSpec = try parseTransactionDateDirective()

            case .keyword("source"):
                try expectFieldEquals("source")
                guard case let .keyword(s) = current else {
                    throw ParserError.unexpectedToken(current, expected: "identifier", at: loc())
                }
                guard let src = TransactionSource(rawValue: s) else {
                    throw ParserError.unexpectedToken(current, expected: "bunq|cash|bank|card|manual|import|private", at: loc())
                }
                source = src; advance()

            case .keyword("identifiers"):
                identifiers = try parseTransactionIdentifiersBlock()

            case .keyword("amount"):
                amount = try parseTransactionAmountBlock()

            case .keyword("details"):     
                details = try parseFreeTextBlock(named: "details")

            case .keyword("counterparty"):
                counterparty = try parseTransactionCounterpartyBlock()

            case .keyword("metadata"):    
                metadata = try parseStringMapBlock(named: "metadata")

            case .keyword("status"):
                try expectFieldEquals("status")
                guard case let .keyword(s) = current else {
                    throw ParserError.unexpectedToken(current, expected: "pending|cleared|reconciled|voided", at: loc())
                }
                guard let st = TransactionStatus(rawValue: s) else {
                    throw ParserError.unexpectedToken(current, expected: "pending|cleared|reconciled|voided", at: loc())
                }
                status = st; advance()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "id/date/source/identifiers/amount/details/counterparty/metadata/status",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let ds = dateSpec else {
            throw ParserError.unexpectedToken(current, expected: "date = … | date infer …", at: loc())
        }
        guard let src = source else {
            throw ParserError.unexpectedToken(current, expected: "source = bunq|cash|bank|card|manual|import|private", at: loc())
        }
        guard let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "amount { … }", at: loc())
        }
        let st = status ?? .pending

        return Transaction(
            id: id,
            date: ds,
            source: src,
            identifiers: identifiers,
            amount: amt,
            details: details,
            counterparty: counterparty,
            metadata: metadata,
            status: st
        )
    }
}
