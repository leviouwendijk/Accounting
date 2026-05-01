import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseMistakeBlock() throws -> Mistake {
        try expect(.keyword("mistake"))
        try beginBlock()

        var details: String?
        var payable: Decimal?
        var receivable: Decimal?

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("details"), .ident("details"):
                // reuse the standard free-text string-block shape
                details = try parseFreeTextBlock(named: "details")

            case .keyword("resolvable"), .ident("resolvable"):
                advance()
                try beginBlock()
                while current != .rBrace && current != .eof {
                    switch current {
                    case .keyword("payable"), .ident("payable"):
                        try expectFieldEquals("payable")
                        payable = try expectDecimal()

                    case .keyword("receivable"), .ident("receivable"):
                        try expectFieldEquals("receivable")
                        receivable = try expectDecimal()

                    default:
                        throw ParserError.unexpectedToken(
                            current, expected: "payable|receivable|}", at: loc()
                        )
                    }
                }
                try endBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "details|resolvable|}", at: loc())
            }
        }

        try endBlock()

        let res = (payable == nil && receivable == nil) ? nil : Resolvable(payable: payable, receivable: receivable)
        return Mistake(details: details, resolvable: res)
    }
}
