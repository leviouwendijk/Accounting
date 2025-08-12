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

            case .keyword("posting"), .keyword("line"):
                entry.lines.append(try parsePostingBlock())

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "date, details, for, posting, or line",
                    at: currentLocation()
                )
            }
        }

        try expect(.rBrace)
        return entry
    }

    private mutating func parseAmountDirective() throws -> (Direction, Decimal) {
        // expects: (debit|credit|dr|cr) = <number>
        guard current == .keyword("debit") || current == .keyword("credit")
            || current == .keyword("dr")   || current == .keyword("cr")
        else {
            throw ParserError.unexpectedToken(current, expected: "debit/credit/dr/cr", at: currentLocation())
        }
        let dir: Direction = (current == .keyword("debit") || current == .keyword("dr")) ? .debit : .credit
        advance()
        try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
        }
        let amt = n
        advance()
        return (dir, amt)
    }

    private mutating func parseSingleInventoryAdjustment(after tok: EntryCompilerToken? = nil) throws -> InventoryAdjustment {
        // supports: adding|addition|add|removing|reduction|remove|rm = <number>
        let t = tok ?? current
        let isAdd = (t == .keyword("adding") || t == .keyword("addition") || t == .keyword("add"))
        let isRed = (t == .keyword("removing") || t == .keyword("reduction") || t == .keyword("remove") || t == .keyword("rm"))
        guard isAdd || isRed else {
            throw ParserError.unexpectedToken(current, expected: "inventory adjustment keyword", at: currentLocation())
        }
        if tok == nil { advance() } // consume the keyword only if caller didn’t pass it
        try expect(.equals)
        guard case let .number(qDec) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
        }
        let qty = (qDec as NSDecimalNumber).doubleValue
        advance()
        return InventoryAdjustment(mutation: isAdd ? .addition : .reduction, count: qty)
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
                (direction, amount) = try parseAmountDirective()

            case .keyword("adding"), .keyword("addition"), .keyword("add"), .keyword("removing"), .keyword("reduction"), .keyword("remove"), .keyword("rm"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: currentLocation()) }
                adjustment = try parseSingleInventoryAdjustment()


            case .keyword("inventory"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: currentLocation()) }
                adjustment = try parseInventoryBlock()

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

    // Read dotted/arrow-separated path segments until a non-segment token.
    private mutating func readFlatSegments() -> [String] {
        var segs: [String] = []
        while true {
            switch current {
            case let .ident(s):  
                segs.append(s); advance()
            case let .number(n): 
                segs.append("\(n)"); advance()
            case let .keyword(k) where k == "inventory":
                segs.append(k); advance()
            default:             
                return segs
            }
            if current == .dot || current == .arrow { advance(); continue }
            return segs
        }
    }

    private mutating func parseInventoryBlock() throws -> InventoryAdjustment {
        try expect(.keyword("inventory"))
        try expect(.lBrace)

        var net: Double = 0.0
        var pendingMutation: InventoryAdjustmentDirection?
        var pendingCount: Double?

        func flushPendingIfReady() throws {
            if let m = pendingMutation, let c = pendingCount {
                net += (m == .addition ? c : -c)
                pendingMutation = nil
                pendingCount = nil
            }
        }

        while current != .rBrace && current != .eof {
            switch current {
            // direct forms: add/remove (+ synonyms)
            case .keyword("addition"), .keyword("adding"), .keyword("add"),
                 .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"):
                let adj = try parseSingleInventoryAdjustment()
                net += (adj.mutation == .addition ? adj.count : -adj.count)

            // split form: mutation = add|remove ; count = <n>
            case .ident("mutation"):
                advance(); try expect(.equals)
                switch current {
                case .keyword("addition"), .keyword("adding"), .keyword("add"):       pendingMutation = .addition
                case .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"):
                    pendingMutation = .reduction
                default:
                    throw ParserError.unexpectedToken(current, expected: "add/remove", at: currentLocation())
                }
                advance()
                try flushPendingIfReady()

            case .ident("count"):
                advance(); try expect(.equals)
                guard case let .number(qDec) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: currentLocation())
                }
                pendingCount = (qDec as NSDecimalNumber).doubleValue
                advance()
                try flushPendingIfReady()

            default:
                throw ParserError.unexpectedToken(current, expected: "inventory field", at: currentLocation())
            }
        }

        try expect(.rBrace)

        // if one of mutation/count was provided without the other
        if (pendingMutation != nil) != (pendingCount != nil) {
            throw ParserError.unexpectedToken(current, expected: "both mutation and count", at: currentLocation())
        }

        // Collapse to a single adjustment (addition for ≥0, reduction for <0)
        let finalDir: InventoryAdjustmentDirection = (net >= 0) ? .addition : .reduction
        let finalCount = abs(net)
        return InventoryAdjustment(mutation: finalDir, count: finalCount)
    }

    private mutating func parsePostingBlock() throws -> Line {
        guard current == .keyword("posting") || current == .keyword("line") else {
            throw ParserError.unexpectedToken(current, expected: "posting or line", at: currentLocation())
        }
        advance()
        try expect(.lBrace)

        var entityPath: EntityPath?
        var accountPath: AccountPath?
        var direction: Direction?
        var amount: Decimal?
        var adjustment: InventoryAdjustment?

        while current != .rBrace && current != .eof {
            switch current {

            case .ident("entity"):
                advance(); try expect(.equals)
                // entity = processes.deliverable.session
                let segs = readFlatSegments()
                guard segs.count >= 2 else {
                    throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: currentLocation())
                }
                let domain = segs.first!
                entityPath = EntityPath(domain: domain, aliasSegments: Array(segs.dropFirst()))

            case .ident("account"):
                advance(); try expect(.equals)
                // number or dotted path
                if case let .number(n) = current { accountPath = AccountPath(segments: ["\(n)"]); advance() }
                else {
                    let segs = readFlatSegments()
                    guard !segs.isEmpty else {
                        throw ParserError.unexpectedToken(current, expected: "number or path", at: currentLocation())
                    }
                    accountPath = AccountPath(segments: segs)
                }

            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                let (dir, amt) = try parseAmountDirective()
                direction = dir
                amount = amt

            case .keyword("inventory"):
                adjustment = try parseInventoryBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "entity/account/debit|credit|dr|cr", at: currentLocation())
            }
        }

        try expect(.rBrace)
        guard let e = entityPath, let a = accountPath, let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "entity, account, and amount", at: currentLocation())
        }
        return Line(entity: e, account: a, direction: dir, amount: amt, adjustment: adjustment)
    }
}
