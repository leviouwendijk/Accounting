import Foundation
import plate
// import Extensions

public extension EntryCompilerParsing {
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

            case .ident("id"), .keyword("id"):
                try expectFieldEquals("id")
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                id = (n as NSDecimalNumber).intValue
                advance()

            case .ident("date"), .keyword("date"):
                dateSpec = try parseTransactionDateDirective()

            case .ident("source"), .keyword("source"):
                try expectFieldEquals("source")
                // accept ident | keyword | "string"
                let raw: String
                switch current {
                case let .ident(s), let .keyword(s), let .string(s):
                    raw = s; advance()
                default:
                    throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }
                if let s = try? TransactionSource.parse(from: raw) {
                    source = s
                } else {
                    source = try TransactionSource.parse(from: raw.lowercased())
                }

            case .ident("identifiers"), .keyword("identifiers"):
                identifiers = try parseTransactionIdentifiersBlock()

            case .ident("amount"), .keyword("amount"):
                amount = try parseTransactionAmountBlock()

            case .ident("details"), .keyword("details"):
                // details { … } (string-block handled by lexer) OR free-text fallback
                details = try parseFreeTextBlock(named: "details")

            case .ident("counterparty"), .keyword("counterparty"):
                counterparty = try parseTransactionCounterpartyBlock()

            case .ident("metadata"), .keyword("metadata"):
                metadata = try parseStringMapBlock(named: "metadata")

            case .ident("status"), .keyword("status"):
                try expectFieldEquals("status")
                let raw: String
                switch current {
                case let .ident(s), let .keyword(s), let .string(s): raw = s; advance()
                default: 
                    throw ParserError.unexpectedToken(current, expected: "pending|cleared|reconciled|voided", at: loc())
                }
                // guard let st = TransactionStatus(rawValue: raw) else {
                //     throw ParserError.unexpectedToken(current, expected: "pending|cleared|reconciled|voided", at: loc())
                // }
                status = try TransactionStatus.parse(from: raw)

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
