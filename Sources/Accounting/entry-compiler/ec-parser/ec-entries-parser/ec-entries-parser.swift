import Foundation
import plate

public final class EntryCompilerEntriesParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public let defaultTZ: TimeZone
    public init(core: EntryCompilerParserCore, defaultTimeZone: TimeZone) {
        self.core = core
        self.defaultTZ = defaultTimeZone
    }

    public convenience init(tokens: [EntryCompilerToken], defaultTimeZone: TimeZone) {
        self.init(core: EntryCompilerParserCore(tokens: tokens), defaultTimeZone: defaultTimeZone)
    }

    public func parseEntries() throws -> [Entry] {
        var entries: [Entry] = []
        while current != .eof {
            entries.append(try parseEntry())
        }
        return entries
    }

    public func parseEntry() throws -> Entry {
        try expect(.keyword("entry"))
        try expect(.lBrace)

        var entry = Entry()
        var tz = defaultTZ

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("timezone"):
                advance()
                try expect(.lBrace)
                // reuse the settings parser helper to parse an IANA tz ident
                let parsed = try parseTimeZoneValue()
                try expect(.rBrace)
                tz = parsed

            case .keyword("date"):
                advance()
                if case .keyword("infer") = current {
                    advance()
                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(current, expected: "number (day of month)", at: loc())
                    }
                    entry.date = .infer(day: (n as NSDecimalNumber).intValue)
                    advance()

                } else if current == .equals {
                    advance()
                    switch current {
                    case let .number(n):
                        entry.date = .absolute(Date(timeIntervalSince1970: (n as NSDecimalNumber).doubleValue)); advance()
                    case let .dateLiteral(text):
                        entry.date = .absolute(try parseDateLiteral(text, in: tz)); advance()
                    default:
                        throw ParserError.unexpectedToken(current, expected: "number or dateLiteral", at: loc())
                    }

                } else if current == .lBrace {
                    entry.date = .absolute(try parseDateBlock(tz: tz))
                } else {
                    throw ParserError.unexpectedToken(current, expected: "infer, '=', or '{'", at: loc())
                }

            case .keyword("details"):
                advance()
                try expect(.lBrace)
                guard case let .string(txt) = current else {
                    throw ParserError.unexpectedToken(current, expected: "string block", at: loc())
                }
                entry.details = txt
                advance()
                try expect(.rBrace)

            case .keyword("for"), .keyword("in"):
                entry.lines.append(try parseLineOrSwap())

            case .keyword("posting"), .keyword("line"):
                entry.lines.append(try parsePostingBlock())

            default:
                throw ParserError.unexpectedToken(current, expected: "date, details, for, posting, or line", at: loc())
            }
        }

        try expect(.rBrace)
        return entry
    }

    private func parseLineOrSwap() throws -> Line {
        switch current {
        case .keyword("for"):  return try parseLine_for_in()
        case .keyword("in"):   return try parseLine_in_for()
        default:
            throw ParserError.unexpectedToken(current, expected: "for or in", at: loc())
        }
    }

    private func parseLine_for_in() throws -> Line {
        advance() // 'for ... in ...'
        let entity = try parseEntityGroup(flexible: true)
        try expect(.keyword("in"))
        let account = try parseAccountGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }

    private func parseLine_in_for() throws -> Line {
        advance() // 'in ... for ...'
        let account = try parseAccountGroup(flexible: true)
        try expect(.keyword("for"))
        let entity = try parseEntityGroup(flexible: true)
        return try parseLineBody(entity: entity, account: account)
    }

    private func parseLineBody(entity: EntityPath, account: AccountPath) throws -> Line {
        try expect(.lBrace)

        var direction: Direction?
        var amount: Decimal?
        var adjustment: InventoryAdjustment?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("debit"), .keyword("credit"), .keyword("dr"), .keyword("cr"):
                if direction != nil { throw ParserError.unexpectedToken(current, expected: "only one of debit/credit", at: loc()) }
                (direction, amount) = try parseAmountDirective()

            case .keyword("adding"), .keyword("addition"), .keyword("add"),
                 .keyword("removing"), .keyword("reduction"), .keyword("remove"), .keyword("rm"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) }
                adjustment = try parseSingleInventoryAdjustment()

            case .keyword("inventory"):
                if adjustment != nil { throw ParserError.unexpectedToken(current, expected: "single inventory adjustment", at: loc()) }
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

    private func parsePostingBlock() throws -> Line {
        guard current == .keyword("posting") || current == .keyword("line") else {
            throw ParserError.unexpectedToken(current, expected: "posting or line", at: loc())
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
                let segs = readFlatSegments()
                guard segs.count >= 2 else {
                    throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: loc())
                }
                let domain = segs.first!
                entityPath = EntityPath(domain: domain, aliasSegments: Array(segs.dropFirst()))

            case .ident("account"):
                advance(); try expect(.equals)
                if case let .number(n) = current { accountPath = AccountPath(segments: ["\(n)"]); advance() }
                else {
                    let segs = readFlatSegments()
                    guard !segs.isEmpty else {
                        throw ParserError.unexpectedToken(current, expected: "number or path", at: loc())
                    }
                    accountPath = AccountPath(segments: segs)
                }

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
        guard let e = entityPath, let a = accountPath, let dir = direction, let amt = amount else {
            throw ParserError.unexpectedToken(current, expected: "entity, account, and amount", at: loc())
        }
        return Line(entity: e, account: a, direction: dir, amount: amt, adjustment: adjustment)
    }

    private func parseDateLiteral(_ s: String, in tz: TimeZone) throws -> Date {
        let parts = try s.dateParts()                               // plate
        let format: DateParserFormatting
        if parts[0].count == 4 { format = .yyyyMMdd }               // 2025-01-20
        else if parts[2].count == 4 { format = .ddMMyyyy }          // 20-01-2025
        else { format = .yyyyMMdd }                                  // fallback
        let comps = try format.components(from: parts)               // plate
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        guard let d = cal.date(from: comps) else {
            throw ParserError.unexpectedToken(.string(s), expected: "valid date literal", at: loc())
        }
        return d
    }

    private func parseDateBlock(tz: TimeZone) throws -> Date {
        try expect(.lBrace)
        var comps = DateComponents()
        while current != .rBrace {
            switch current {
            case .keyword("year"):
                try expect(.keyword("year")); try expect(.equals)
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                comps.year = (n as NSDecimalNumber).intValue; advance()
            case .keyword("month"):
                try expect(.keyword("month")); try expect(.equals)
                if case let .ident(s) = current { comps.month = monthIndex(from: s); advance() }
                else if case let .number(n) = current { comps.month = (n as NSDecimalNumber).intValue; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc()) }
            case .keyword("day"):
                try expect(.keyword("day")); try expect(.equals)
                guard case let .number(n) = current else { throw ParserError.unexpectedToken(current, expected: "number", at: loc()) }
                comps.day = (n as NSDecimalNumber).intValue; advance()
            default:
                throw ParserError.unexpectedToken(current, expected: "year, month, or day", at: loc())
            }
        }
        try expect(.rBrace)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = tz
        return cal.date(from: comps) ?? Date()
    }
}
