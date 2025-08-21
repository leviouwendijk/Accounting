import Foundation

public extension EntryCompilerParsing {
    func parseLineBody(entity: EntityPath, account: AccountPath) throws -> Line {
        try expect(.lBrace)

        var direction: Direction?
        var amount: Decimal?
        var adjustment: InventoryAdjustment?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                if direction != nil { 
                    throw ParserError.unexpectedToken(current, expected: "only one of debit/credit", at: loc()) 
                }
                (direction, amount) = try parseAmountDirective()

            case .keyword("adding"), .keyword("addition"), .keyword("add"),
                 .keyword("removing"), .keyword("reduction"), .keyword("remove"), .keyword("rm"):
                if adjustment != nil { 
                    throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) 
                }
                adjustment = try parseSingleInventoryAdjustment()

            case .keyword("inventory"):
                if adjustment != nil { 
                    throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) 
                }
                adjustment = try parseInventoryBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "debit/credit or adding/removing", at: loc())
            }
        }

        try expect(.rBrace)
        guard let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "posting amount (debit/credit = …)", at: loc())
        }
        return Line(entity: entity, account: account, direction: dir, amount: amt, adjustment: adjustment)
    }

    func parseLineOrSwap() throws -> Line {
        switch current {
        case .keyword("for"):  return try parseLine_for_in()
        case .keyword("in"):   return try parseLine_in_for()
        default:
            throw ParserError.unexpectedToken(current, expected: "for or in", at: loc())
        }
    }

    func parseLine_for_in() throws -> Line {
        advance() // 'for ... in ...'
        let entity = try parseEntityGroup(flexible: true)
        try expect(.keyword("in"))
        let account = try parseAccountGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }

    func parseLine_in_for() throws -> Line {
        advance() // 'in ... for ...'
        let account = try parseAccountGroup(flexible: true)
        try expect(.keyword("for"))
        let entity = try parseEntityGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }
}
