// import Foundation

// public extension EntryCompilerParsing {
//     // transaction { ... }
//     // --- helpers ---

//     /// Accepts:
//     ///   date = 2025-08-21
//     ///   date { year=2025 month=08 day=21 }
//     ///   date infer 15
//     @inlinable
//     func parseTransactionDateDirective() throws -> DateSpecification {
//         try parseDateOrInfer(tz: .current, allowUnixEpoch: false)
//     }

//     @inlinable
//     func parseTransactionIdentifiersBlock() throws -> TransactionIdentifiers {
//         try expect(.keyword("identifiers"))
//         try beginBlock()
//         var out = TransactionIdentifiers()
//         while current != .rBrace && current != .eof {
//             switch current {
//             case .ident("platform_account_id"), .keyword("platform_account_id"):
//                 advance(); try expect(.equals)
//                 out.platformAccountID = try expectInteger()

//             case .ident("platform_transaction_id"), .keyword("platform_transaction_id"):
//                 advance(); try expect(.equals)
//                 out.platformTransactionID = try expectInteger()

//             default:
//                 throw ParserError.unexpectedToken(
//                     current,
//                     expected: "platform_account_id/platform_transaction_id",
//                     at: loc()
//                 )
//             }
//         }
//         try endBlock()
//         return out
//     }

//     @inlinable
//     func parseTransactionAmountBlock() throws -> TransactionAmount {
//         if case .keyword("amount") = current { advance() }
//         else if case .ident("amount") = current { advance() }
//         else { try expect(.keyword("amount")) } // nice error if truly wrong

//         try beginBlock()
//         var currency: String?
//         var gross: Decimal?
//         var fee: Decimal?
//         var net: Decimal?

//         while current != .rBrace && current != .eof {
//             switch current {
//             case .keyword("currency"), .ident("currency"):
//                 try expectFieldEquals("currency")
//                 switch current {
//                 case let .ident(s), let .keyword(s), let .string(s):
//                     currency = s; advance()
//                 default:
//                     throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
//                 }

//             case .keyword("gross"), .ident("gross"):
//                 try expectFieldEquals("gross")
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 gross = n; advance()

//             case .keyword("fee"), .ident("fee"):
//                 try expectFieldEquals("fee")
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 fee = n; advance()

//             case .keyword("net"), .ident("net"):
//                 try expectFieldEquals("net")
//                 guard case let .number(n) = current else {
//                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
//                 }
//                 net = n; advance()

//             default:
//                 throw ParserError.unexpectedToken(current, expected: "currency/gross[/fee][/net]", at: loc())
//             }
//         }

//         try endBlock()
//         guard let c = currency, let g = gross else {
//             throw ParserError.unexpectedToken(current, expected: "currency and gross", at: loc())
//         }
//         return TransactionAmount(currency: c, gross: g, fee: fee, net: net)
//     }

//     @inlinable
//     func parseTransactionCounterpartyBlock() throws -> TransactionCounterparty {
//         if case .keyword("counterparty") = current { advance() }
//         else if case .ident("counterparty") = current { advance() }
//         else { try expect(.keyword("counterparty")) }

//         try beginBlock()
//         var name: String?
//         var iban: String?
//         var bic:  String?

//         while current != .rBrace && current != .eof {
//             switch current {
//             case .keyword("name"), .ident("name"):
//                 advance()
//                 if current == .lBrace {
//                     // name { ACME B.V. }  — lexer now gives one .string token
//                     name = try parseStringBlock(named: "")   // header already consumed
//                 } else {
//                     try expect(.equals)
//                     if current == .lBrace {
//                         name = try readVerbatimBlockBody()   // also supports brace-wrapped
//                     } else {
//                         // name = ACME B.V.  — eat until next known key in this block
//                         name = readUnquotedValue(untilNextKeys: ["iban","bic"])
//                     }
//                 }

//             case .keyword("iban"), .ident("iban"):
//                 try expectFieldEquals("iban")
//                 switch current {
//                 case let .string(s), let .ident(s), let .keyword(s): iban = s; advance()
//                 default: throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc())
//                 }

//             case .keyword("bic"), .ident("bic"):
//                 try expectFieldEquals("bic")
//                 switch current {
//                 case let .string(s), let .ident(s), let .keyword(s): bic = s; advance()
//                 default: throw ParserError.unexpectedToken(current, expected: "string|identifier", at: loc())
//                 }

//             default:
//                 throw ParserError.unexpectedToken(current, expected: "name/iban/bic", at: loc())
//             }
//         }

//         try endBlock()
//         return TransactionCounterparty(name: name, iban: iban, bic: bic)
//     }
// }
