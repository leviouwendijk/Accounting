import Foundation

public extension EntryCompilerParsing {
    func parsePostingBlock() throws -> Line {
        guard current == .keyword("posting") || current == .keyword("line") else {
            throw ParserError.unexpectedToken(current, expected: "posting or line", at: loc())
        }
        advance()
        try expect(.lBrace)

        var entityRef: EntityRef?
        var accountRef: AccountRef?
        var direction: Direction?
        var amount: Decimal?
        var adjustment: InventoryAdjustment?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("entity"):
                advance(); try expect(.equals)
                let segs = readFlatSegments()
                guard segs.count >= 2 else {
                    throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: loc())
                }
                entityRef = try makeEntityRef(from: segs)

            case .ident("account"):
                advance()
                try expect(.equals)
                accountRef = try parseAccountRefFlexible()

            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                let (dir, amt) = try parseAmountDirective()
                direction = dir; amount = amt

            case .keyword("inventory"):
                adjustment = try parseInventoryBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "entity/account/debit|credit|dr|cr", at: loc())
            }
        }

        try expect(.rBrace)
        guard let e = entityRef, let a = accountRef, let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "entity, account, and amount", at: loc())
        }
        return Line(entity: e, account: a, direction: dir, amount: amt, adjustment: adjustment)
    }
}
