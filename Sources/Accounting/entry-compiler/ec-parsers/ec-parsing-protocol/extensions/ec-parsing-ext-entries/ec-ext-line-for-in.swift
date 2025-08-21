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
                if direction != nil { throw ParserError.unexpectedToken(current, expected: "only one of debit/credit", at: loc()) }
                (direction, amount) = try parseAmountDirective()        // existing helper
            case .keyword("adding"), .keyword("addition"), .keyword("add"),
                 .keyword("removing"), .keyword("reduction"), .keyword("remove"), .keyword("rm"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) }
                adjustment = try parseSingleInventoryAdjustment()       // existing helper
            case .keyword("inventory"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) }
                adjustment = try parseInventoryBlock()                  // existing helper
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
    func parseEntityTargets() throws -> [EntityPath] {
        // Single flexible form stays supported (legacy helpers) :contentReference[oaicite:3]{index=3}
        if current != .lPar {
            return [try parseEntityGroup(flexible: true)]
        }

        try expect(.lPar)
        var out: [EntityPath] = []
        while current != .rPar && current != .eof {
            // Read one entity path (arrow/dot separated). Reuse flat segment reader. :contentReference[oaicite:4]{index=4}
            let segs = readFlatSegments()
            guard segs.count >= 2 else {
                throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: loc())
            }
            let domain = segs[0]
            out.append(EntityPath(domain: domain, aliasSegments: Array(segs.dropFirst())))

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
    func parseAccountTargets() throws -> [AccountPath] {
        // Single flexible form stays supported (legacy helpers) :contentReference[oaicite:5]{index=5}
        if current != .lPar && current != .number(0) && !(current == .ident("account")) && !(current == .ident("")) {
            return [try parseAccountGroup(flexible: true)]
        }

        // Single number without parens
        if case let .number(n) = current {
            advance()
            return [AccountPath(segments: ["\(n)"])]
        }

        // Single "account(...)" legacy
        if case .ident("account") = current, peekTokenIsLPar() {
            return [try parseAccountGroup(flexible: true)]
        }

        // List in parens
        try expect(.lPar)
        var out: [AccountPath] = []
        while current != .rPar && current != .eof {
            // Optional "account" prefix in lists: "(account 2301, 10201, …)"
            if case .ident("account") = current { advance() }

            if case let .number(n) = current {
                out.append(AccountPath(segments: ["\(n)"])); advance()
            } else {
                // dotted/arrow path
                let segs = readFlatSegments()
                guard !segs.isEmpty else {
                    throw ParserError.unexpectedToken(current, expected: "account number or path", at: loc())
                }
                out.append(AccountPath(segments: segs))
            }

            if current == .comma { advance(); continue }
            break
        }
        try expect(.rPar)
        return out
    }

    func expandLines(
        entities: [EntityPath],
        accounts: [AccountPath],
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
