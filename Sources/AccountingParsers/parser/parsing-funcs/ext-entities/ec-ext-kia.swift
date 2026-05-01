import Foundation
import Accounting

public extension EntryCompilerParsing {
    @inlinable
    func parseKIABlock() throws -> KIADraft {
        try expect(.lBrace)

        var draft: KIADraft?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("shares"), .keyword("shares"):
                advance()
                draft = try parseKIASharesBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "shares",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        guard let draft else {
            throw ParserError.unexpectedToken(
                current,
                expected: "kia shares block",
                at: loc()
            )
        }

        return draft
    }

    @inlinable
    func parseKIASharesBlock() throws -> KIADraft {
        try expect(.lBrace)

        var percentageShares: [KIAOwnerShareDraft]?
        var amountShares: [KIAOwnerShareDraft]?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("percentage"), .keyword("percentage"):
                advance()
                percentageShares = try parseKIAOwnerValueBlock()

            case .ident("amount"), .keyword("amount"):
                advance()
                amountShares = try parseKIAOwnerValueBlock()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "percentage|amount",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)

        if let percentageShares, amountShares == nil {
            return KIADraft(
                mode: .percentage,
                shares: percentageShares
            )
        }

        if let amountShares, percentageShares == nil {
            return KIADraft(
                mode: .amount,
                shares: amountShares
            )
        }

        throw ParserError.unexpectedToken(
            current,
            expected: "exactly one of percentage or amount",
            at: loc()
        )
    }

    @inlinable
    func parseKIAOwnerValueBlock() throws -> [KIAOwnerShareDraft] {
        try expect(.lBrace)

        var result: [KIAOwnerShareDraft] = []

        while current != .rBrace && current != .eof {
            let ownerRef = try parseEntityRefFlexible()

            try expect(.equals)
            let value = try expectDecimal()

            result.append(
                KIAOwnerShareDraft(
                    owner: ownerRef,
                    value: value
                )
            )
        }

        try expect(.rBrace)
        return result
    }
}
