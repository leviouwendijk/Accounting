import Foundation

public extension EntryCompilerParsing {
    func parseLineBody(entity: EntityRef, account: AccountRef, at lineLoc: SourceLocation?) throws -> Line {
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

            case .keyword("inventory"), .ident("inventory"):
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
        return Line(entity: entity, account: account, direction: dir, amount: amt, adjustment: adjustment, location: lineLoc)
    }

    // legacy, singulars:
    func parseLineOrSwap() throws -> Line {
        switch current {
        case .keyword("for"):  return try parseLine_for_in()
        case .keyword("in"):   return try parseLine_in_for()
        default:
            throw ParserError.unexpectedToken(current, expected: "for or in", at: loc())
        }
    }

    func parseLine_for_in() throws -> Line {
        let lineLoc = loc()
        advance() // 'for ... in ...'
        let entity = try parseEntityRefFlexible()
        try expect(.keyword("in"))
        let account = try parseAccountRefFlexible()
        return try parseLineBody(entity: entity, account: account, at: lineLoc)
    }

    func parseLine_in_for() throws -> Line {
        let lineLoc = loc()
        advance() // 'in ... for ...'
        let account = try parseAccountRefFlexible()
        try expect(.keyword("for"))
        let entity = try parseEntityRefFlexible()
        return try parseLineBody(entity: entity, account: account, at: lineLoc)
    }
}

// pluralized:
public extension EntryCompilerParsing {
    // plural dispatcher (now returns `[Line]` instead of `Line`)
    func parseMultiLinesOrSwap() throws -> [Line] {
        switch current {
        case .keyword("for"):  return try parseMultiLines_for_in()
        case .keyword("in"):   return try parseMultiLines_in_for()
        default:
            throw ParserError.unexpectedToken(current, expected: "for or in", at: loc())
        }
    }

    // for (…) in (…)
    func parseMultiLines_for_in() throws -> [Line] {
        advance() // 'for'
        let entities = try parseEntityTargets()   // NEW: list-aware
        try expect(.keyword("in"))
        let accounts = try parseAccountTargets()  // NEW: list-aware

        let payload = try parseLineBodyPayload()  // parse { dr/cr, inventory? }
        return expandLines(entities: entities, accounts: accounts, payload: payload)
    }

    // in (…) for (…)
    func parseMultiLines_in_for() throws -> [Line] {
        advance() // 'in'
        let accounts = try parseAccountTargets()

        // NEW: support block after 'in (...)'
        if current == .lBrace {
            try expect(.lBrace)
            var out: [Line] = []
            while current != .rBrace && current != .eof {
                try expect(.keyword("for"))
                let entities = try parseEntityTargets()
                let payload = try parseLineBodyPayload()
                out.append(contentsOf: expandLines(entities: entities, accounts: accounts, payload: payload))
            }
            try expect(.rBrace)
            return out
        }

        // Existing inline form: in (…) for (…) { … }
        try expect(.keyword("for"))
        let entities = try parseEntityTargets()
        let payload = try parseLineBodyPayload()
        return expandLines(entities: entities, accounts: accounts, payload: payload)
    }

    // note: we keep the existing `parseLineBody(entity:account:)` for legacy single-target flows.
    func parseLineBodyPayload() throws -> (Direction, Decimal, InventoryAdjustment?) {
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

            case .keyword("inventory"),
                .ident("adjustment"):
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
        return (dir, amt, adjustment)
    }

    // Accepts:
    //   for (objects -> usable -> vehicle -> unit(honda_crv), objects -> … -> unit(tesla_y)) …
    //   for liquids.money.main …                        // single, bare
    //   for (liquids.money.main) …                      // single in parens
    func parseEntityTargets() throws -> [EntityRef] {
        if current != .lPar { return [try parseEntityRefFlexible()] }
        try expect(.lPar)
        var out: [EntityRef] = []
        while current != .rPar && current != .eof {
            let segs = readFlatSegments()
            out.append(try makeEntityRef(from: segs))
            if current == .comma { advance(); continue }
            break
        }
        try expect(.rPar)
        return out
    }

    // Accepts:
    //   in (account 2301, 10201, assets.bank.main)
    //   in 10201
    //   in (10201)
    func parseAccountTargets() throws -> [AccountRef] {
        if current == .lPar {
            return try parseAccountRefListInParens()
        }
        return [try parseAccountRefFlexible()]
    }

    func expandLines(
        entities: [EntityRef],
        accounts: [AccountRef],
        payload: (Direction, Decimal, InventoryAdjustment?)
    ) -> [Line] {
        let (dir, amt, adj) = payload
        var lines: [Line] = []
        for e in entities {
            for a in accounts {
                lines.append(Line(entity: e, account: a, direction: dir, amount: amt, adjustment: adj))
            }
        }
        return lines
    }
}
