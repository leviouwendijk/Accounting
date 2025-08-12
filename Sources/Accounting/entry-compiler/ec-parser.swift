import Foundation
import plate

public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(EntryCompilerToken, expected: String, at: SourceLocation)
    case unterminatedBlock(SourceLocation)

    public var description: String {
        switch self {
        case let .unexpectedToken(tok, expected, loc):
            return "Unexpected token \(tok) at \(loc). Expected \(expected)."
        case let .unterminatedBlock(loc):
            return "Unterminated block starting at \(loc)."
        }
    }
}

public struct EntryCompilerParser {
    private let tokens: [EntryCompilerToken]
    private var index = 0
    private var line = 1, column = 1

    public init(tokens: [EntryCompilerToken]) {
        self.tokens = tokens
    }

    private var current: EntryCompilerToken {
        return index < tokens.count ? tokens[index] : .eof
    }

    private mutating func advance() {
        index += 1
        column += 1
    }

    private mutating func expect(_ expected: EntryCompilerToken) throws {
        guard current == expected else {
            throw ParserError.unexpectedToken(current, expected: "\(expected)", at: .init(line: line, column: column))
        }
        advance()
    }

    public mutating func parseEntries() throws -> [Entry] {
        var entries: [Entry] = []
        while current != .eof {
            entries.append(try parseEntry())
        }
        return entries
    }

    private mutating func parseEntry() throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)

        var entry = Entry()

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("date"):
                advance()
                // date infer <day>
                if case .keyword("infer") = current {
                    advance()
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number (day of month)", at: currentLocation())
                    }
                    entry.date = .infer(day: (n as NSDecimalNumber).intValue)
                    advance()

                } else if current == .equals {
                    // date = <unix-seconds> | <date-literal>
                    advance()
                    switch current {
                    case let .number(n):
                        entry.date = .absolute(Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue))
                        advance()
                    case let .dateLiteral(text):
                        entry.date = .absolute(try text.date())
                        advance()
                    default:
                        throw ParserError.unexpectedToken(current, expected: "number or dateLiteral", at: currentLocation())
                    }

                } else if current == .lBrace {
                    // date { year=.. month=.. day=.. }
                    entry.date = .absolute(try parseDateBlock())
                } else {
                    throw ParserError.unexpectedToken(current, expected: "infer, '=', or '{'", at: currentLocation())
                }

            case .keyword("details"):
                advance()                       // consume 'details'
                try expect(.lBrace)            // now expect '{'
                guard case let .string(txt) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string block", at: currentLocation())
                }
                entry.details = txt
                advance()                       // consume string
                try expect(.rBrace)            // consume closing '}'

            // case .keyword("for"):
            //     entry.lines.append(try parseLine())

            case .keyword("for"), .keyword("in"):
                entry.lines.append(try parseLineOrSwap())

            case .keyword("posting"):
                entry.lines.append(try parsePostingBlock())

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "date, details, or for",
                    at: currentLocation()
                )
            }
        }

        try expect(.rBrace)
        return entry
    }

    private mutating func parseLine() throws -> Line {
        advance() // consumed 'for'
        let entity = try parseEntityPath()
        try expect(.keyword("in"))
        let account = try parseAccountPath()
        try expect(.lBrace)

        // mandatory posting amount
        var direction: Direction?
        var amount: Decimal?

        // optional single inventory adjustment
        var adjustment: InventoryAdjustment?

        // line body: one or more statements in any order
        lineBody: while current != .rBrace && current != .eof {
            switch current {

            case .keyword("debit"), .keyword("credit"):
                if direction != nil {
                    throw ParserError.unexpectedToken(current, expected: "only one of debit/credit per line", at: currentLocation())
                }
                let isDebit = (current == .keyword("debit") || current == .keyword("dr"))
                // let isCredit = (current == .keyword("credit") || current == .keyword("rm"))
                let isCredit = (current == .keyword("credit") || current == .keyword("cr"))
                direction = isDebit ? .debit : (isCredit ? .credit : nil)
                advance()
                try expect(.equals)
                guard case let .number(val) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                amount = val
                advance()

            case .keyword("adding"), .keyword("removing"), .keyword("add"), .keyword("remove"), .keyword("rm"), .keyword("reduction"):
                if adjustment != nil {
                    throw ParserError.unexpectedToken(current, expected: "only one inventory adjustment per line", at: currentLocation())
                }
                let kindTok = current
                advance()
                try expect(.equals)
                guard case let .number(qtyDec) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                let qty = (qtyDec as NSDecimalNumber).doubleValue
                let dir: InventoryAdjustmentDirection = (kindTok == .keyword("adding") || kindTok == .keyword("add")) ? .addition : .reduction
                adjustment = InventoryAdjustment(mutation: dir, count: qty)
                advance()

            default:
                // unknown token in line body
                throw ParserError.unexpectedToken(current, expected: "debit/credit or adding/removing", at: currentLocation())
            }
        }

        try expect(.rBrace)

        guard let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "posting amount (debit/credit = …)", at: currentLocation())
        }

        return Line(
            entity: entity,
            account: account,
            direction: dir,
            amount: amt,
            adjustment: adjustment
        )
    }

    private mutating func parseLineOrSwap() throws -> Line {
        // supports:
        //   for (entity.path) in <account> { ... }
        //   in <account> for (entity.path) { ... }
        switch current {
        case .keyword("for"):  return try parseLine_for_then_in()
        case .keyword("in"):   return try parseLine_in_then_for()
        default:
            throw ParserError.unexpectedToken(current, expected: "for or in", at: currentLocation())
        }
    }

    private mutating func parseLine_for_then_in() throws -> Line {
        advance() // 'for'
        let entity = try parseEntityGroup(flexible: true)
        try expect(.keyword("in"))
        let account = try parseAccountGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }

    private mutating func parseLine_in_then_for() throws -> Line {
        advance() // 'in'
        let account = try parseAccountGroup(flexible: true)
        try expect(.keyword("for"))
        let entity = try parseEntityGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }

    private mutating func parseEntityPath() throws -> EntityPath {
        // entity(people->levi_ouwendijk)
        guard case .ident("entity") = current else {
            throw ParserError.unexpectedToken(current, expected: "entity", at: .init(line: line, column: column))
        }
        advance()
        try expect(.lPar)
        // collect segments until ')'
        var segments: [String] = []
        while current != .rPar && current != .eof {
            if case let .ident(s) = current {
                segments.append(s)
            }
            advance()
            if current == .arrow || current == .dot {
                advance()
            }
        }
        try expect(.rPar)
        guard segments.count >= 2 else {
            throw ParserError.unexpectedToken(current, expected: "domain.alias", at: .init(line: line, column: column))
        }
        let domain = segments.first!
        let alias = Array(segments.dropFirst())
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    private mutating func parseAccountPath() throws -> AccountPath {
        // account(assets.cash.bank_balances)
        guard case .ident("account") = current else {
            throw ParserError.unexpectedToken(current, expected: "account", at: .init(line: line, column: column))
        }
        advance()
        try expect(.lPar)
        var segments: [String] = []
        while current != .rPar && current != .eof {
            if case let .ident(s) = current {
                segments.append(s)
            }
            advance()
            if current == .dot || current == .arrow {
                advance()
            }
        }
        try expect(.rPar)
        return AccountPath(segments: segments)
    }

    private mutating func parseDateBlock() throws -> Date {
        try expect(.lBrace)

        var comps = DateComponents()
        while current != .rBrace {
            switch current {
            case .keyword("year"):
                try expect(.keyword("year"))
                try expect(.equals)
                // extract number
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current,
                        expected: "number", at: currentLocation())
                }
                comps.year = (n as NSDecimalNumber).intValue
                advance()

            case .keyword("month"):
                try expect(.keyword("month"))
                try expect(.equals)
                // extract identifier or number
                if case let .ident(s) = current {
                    let mstr = s.lowercased()
                    // map "jan"/"january"/"01"→1 etc.
                    comps.month = monthIndex(from: mstr)
                    advance()
                } else if case let .number(n) = current {
                    comps.month = (n as NSDecimalNumber).intValue
                    advance()
                } else {
                    throw ParserError.unexpectedToken(current,
                        expected: "identifier or number", at: currentLocation())
                }

            case .keyword("day"):
                try expect(.keyword("day"))
                try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current,
                        expected: "number", at: currentLocation())
                }
                comps.day = (n as NSDecimalNumber).intValue
                advance()

            default:
                throw ParserError.unexpectedToken(current,
                    expected: "year, month, or day", at: currentLocation())
            }
        }

        try expect(.rBrace)
        return Calendar.current.date(from: comps) ?? Date()
    }

    private func monthIndex(from m: String) -> Int {
        let lower = m.lowercased()
        let names = Calendar.current.monthSymbols.map { $0.lowercased() }
        if let idx = names.firstIndex(of: lower) { return idx + 1 }
        let abbr = Calendar.current.shortMonthSymbols.map { $0.lowercased() }
        if let idx = abbr.firstIndex(of: lower) { return idx + 1 }
        return Int(m) ?? 1
    }

    private func currentLocation() -> SourceLocation {
        return SourceLocation(line: line, column: column)
    }

    private mutating func parseEntityGroup(flexible: Bool) throws -> EntityPath {
        // (liquids->money->main)  OR  (liquids.money.main)
        // also allow: entity(liquids.money.main) if you still want the old form
        if case .ident("entity") = current { return try parseEntityPath() } // legacy
        try expect(.lPar)
        let (domain, alias) = try readSegmentsUntilRPar()
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    private mutating func parseAccountGroup(flexible: Bool) throws -> AccountPath {
        // account(...) (legacy), or a raw number, or a dotted/arrow group in parens
        if case .ident("account") = current { return try parseAccountPath() } // legacy
        switch current {
        case let .number(n):
            advance()
            return AccountPath(segments: ["\(n)"])
        case .lPar:
            try expect(.lPar)
            let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
            return AccountPath(segments: segs)
        default:
            throw ParserError.unexpectedToken(current, expected: "number or (account.path)", at: currentLocation())
        }
    }

    private mutating func readSegmentsUntilRPar(allowAllAsAlias: Bool = false) throws -> (String, [String]) {
        var segs: [String] = []
        while current != .rPar && current != .eof {
            switch current {
            case let .ident(s): segs.append(s); advance()
            case let .number(n): segs.append("\(n)"); advance()
            default: advance()
            }
            if current == .arrow || current == .dot { advance() }
        }
        try expect(.rPar)
        guard !segs.isEmpty else {
            throw ParserError.unexpectedToken(current, expected: "non-empty path", at: currentLocation())
        }
        if allowAllAsAlias { return (segs.first ?? "", segs) }
        let domain = segs.removeFirst()
        return (domain, segs)
    }

    private mutating func parseLineBody(entity: EntityPath, account: AccountPath) throws -> Line {
        try expect(.lBrace)

        var direction: Direction?
        var amount: Decimal?
        var adjustment: InventoryAdjustment?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                if direction != nil { throw ParserError.unexpectedToken(current, expected: "only one of debit/credit", at: currentLocation()) }
                let isDebit  = (current == .keyword("debit") || current == .keyword("dr"))
                let isCredit = (current == .keyword("credit") || current == .keyword("cr"))
                direction = isDebit ? .debit : (isCredit ? .credit : nil)
                advance()
                try expect(.equals)
                guard case let .number(val) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                amount = val
                advance()

            case .keyword("adding"), .keyword("add"), .keyword("removing"), .keyword("remove"), .keyword("reduction"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: currentLocation()) }
                let kindTok = current; advance()
                try expect(.equals)
                guard case let .number(qtyDec) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                let qty = (qtyDec as NSDecimalNumber).doubleValue
                let dir: InventoryAdjustmentDirection =
                    (kindTok == .keyword("adding") || kindTok == .keyword("add"))
                    ? .addition : .reduction
                adjustment = InventoryAdjustment(mutation: dir, count: qty)
                advance()

            default:
                throw ParserError.unexpectedToken(current, expected: "debit/credit or adding/removing", at: currentLocation())
            }
        }

        try expect(.rBrace)
        guard let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "posting amount (debit/credit = …)", at: currentLocation())
        }
        return Line(entity: entity, account: account, direction: dir, amount: amt, adjustment: adjustment)
    }

    private mutating func parsePostingBlock() throws -> Line {
        try expect(.keyword("posting"))
        try expect(.lBrace)

        var entityPath: EntityPath?
        var accountPath: AccountPath?
        var direction: Direction?
        var amount: Decimal?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("entity"):
                advance(); try expect(.equals)
                // entity = processes.deliverable.session   (no parens here)
                var segs: [String] = []
                while case let .ident(s) = current {
                    segs.append(s); advance()
                    if current == .dot || current == .arrow { advance() }
                    else { break }
                }
                guard segs.count >= 2 else { throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: currentLocation()) }
                let domain = segs.removeFirst()
                entityPath = EntityPath(domain: domain, aliasSegments: segs)

            case .ident("account"):
                advance(); try expect(.equals)
                switch current {
                case let .number(n): accountPath = AccountPath(segments: ["\(n)"]); advance()
                case let .ident(s):
                    var segs = [s]; advance()
                    while current == .dot || current == .arrow {
                        advance()
                        if case let .ident(next) = current { segs.append(next); advance() }
                        else if case let .number(n) = current { segs.append("\(n)"); advance() }
                    }
                    accountPath = AccountPath(segments: segs)
                default:
                    throw ParserError.unexpectedToken(current, expected: "number or path", at: currentLocation())
                }

            // case .ident("debit"), .ident("credit"), .ident("dr"), .ident("cr"):
            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                let tok = current; advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                amount = n
                direction = (tok == .keyword("debit") || tok == .keyword("dr")) ? .debit : .credit
                advance()


            case .keyword("inventory"):
                advance()
                try expect(.lBrace)
                // parse inner inventory fields
                while current != .rBrace && current != .eof {
                    switch current {
                    case .keyword("addition"), .keyword("add"):
                        advance(); try expect(.equals)
                        guard case let .number(qty) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation()) }
                        // store qty in some postingInventoryAdditions array/struct
                        advance()

                    case .keyword("remove"), .keyword("rm"):
                        advance(); try expect(.equals)
                        guard case let .number(qty) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation()) }
                        // store qty in postingInventoryReductions array/struct
                        advance()

                    default:
                        throw ParserError.unexpectedToken(current, expected: "inventory field", at: currentLocation())
                    }
                }
                try expect(.rBrace)

            default:
                throw ParserError.unexpectedToken(current, expected: "entity/account/debit|credit|dr|cr", at: currentLocation())
            }
        }

        try expect(.rBrace)
        guard let e = entityPath, let a = accountPath, let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "entity, account, and amount", at: currentLocation())
        }
        return Line(entity: e, account: a, direction: dir, amount: amt)
    }
}
