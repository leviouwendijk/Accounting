import Foundation

// Parsing functions for Entries
public extension EntryCompilerParsing {
    // ---- Core shortcuts
    @inline(__always) var current: EntryCompilerToken { core.current }
    @inline(__always) func advance() { core.advance() }
    @inline(__always) func expect(_ t: EntryCompilerToken) throws { try core.expect(t) }
    @inline(__always) func loc() -> SourceLocation { core.currentLocation() }

    // ---- Generic segment readers
    @inline(__always)
    func readFlatSegments() -> [String] {
        var segs: [String] = []
        while true {
            switch current {
            case let .ident(s): segs.append(s); advance()
            case let .number(n): segs.append("\(n)"); advance()
            case let .keyword(k) where k == "inventory": segs.append(k); advance()
            default: return segs
            }
            if current == .dot || current == .arrow { advance(); continue }
            return segs
        }
    }

    func readSegmentsUntilRPar(allowAllAsAlias: Bool = false) throws -> (String, [String]) {
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
            throw ParserError.unexpectedToken(current, expected: "non-empty path", at: loc())
        }
        if allowAllAsAlias { return (segs.first ?? "", segs) }
        var copy = segs
        let domain = copy.removeFirst()
        return (domain, copy)
    }

    // ---- Common atoms used across parsers
    func parseAmountDirective() throws -> (Direction, Decimal) {
        guard current == .keyword("debit") || current == .keyword("credit")
           || current == .keyword("dr")    || current == .keyword("cr")
        else {
            throw ParserError.unexpectedToken(current, expected: "debit/credit/dr/cr", at: loc())
        }
        let dir: Direction = (current == .keyword("debit") || current == .keyword("dr")) ? .debit : .credit
        advance()
        try expect(.equals)
        guard case let .number(n) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        let amt = n
        advance()
        return (dir, amt)
    }

    func parseSingleInventoryAdjustment(after tok: EntryCompilerToken? = nil) throws -> InventoryAdjustment {
        let t = tok ?? current
        let isAdd = (t == .keyword("adding") || t == .keyword("addition") || t == .keyword("add"))
        let isRed = (t == .keyword("removing") || t == .keyword("reduction") || t == .keyword("remove") || t == .keyword("rm"))
        guard isAdd || isRed else {
            throw ParserError.unexpectedToken(current, expected: "inventory adjustment keyword", at: loc())
        }
        if tok == nil { advance() }
        try expect(.equals)
        guard case let .number(qDec) = current else {
            throw ParserError.unexpectedToken(current, expected: "number", at: loc())
        }
        let qty = (qDec as NSDecimalNumber).doubleValue
        advance()
        return InventoryAdjustment(mutation: isAdd ? .addition : .reduction, count: qty)
    }

    func parseInventoryBlock() throws -> InventoryAdjustment {
        try expect(.keyword("inventory"))
        try expect(.lBrace)

        var net: Double = 0.0
        var pendingMutation: InventoryAdjustmentDirection?
        var pendingCount: Double?

        func flushPendingIfReady() {
            if let m = pendingMutation, let c = pendingCount {
                net += (m == .addition ? c : -c)
                pendingMutation = nil
                pendingCount = nil
            }
        }

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("addition"), .keyword("adding"), .keyword("add"),
                 .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"):
                let adj = try parseSingleInventoryAdjustment()
                net += (adj.mutation == .addition ? adj.count : -adj.count)

            case .ident("mutation"):
                advance(); try expect(.equals)
                switch current {
                case .keyword("addition"), .keyword("adding"), .keyword("add"): pendingMutation = .addition
                case .keyword("reduction"), .keyword("removing"), .keyword("remove"), .keyword("rm"): pendingMutation = .reduction
                default:
                    throw ParserError.unexpectedToken(current, expected: "add/remove", at: loc())
                }
                advance(); flushPendingIfReady()

            case .ident("count"):
                advance(); try expect(.equals)
                guard case let .number(qDec) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                pendingCount = (qDec as NSDecimalNumber).doubleValue
                advance(); flushPendingIfReady()

            default:
                throw ParserError.unexpectedToken(current, expected: "inventory field", at: loc())
            }
        }

        try expect(.rBrace)
        if (pendingMutation != nil) != (pendingCount != nil) {
            throw ParserError.unexpectedToken(current, expected: "both mutation and count", at: loc())
        }
        let finalDir: InventoryAdjustmentDirection = (net >= 0) ? .addition : .reduction
        let finalCount = abs(net)
        return InventoryAdjustment(mutation: finalDir, count: finalCount)
    }

    func parseEntityPath() throws -> EntityPath {
        guard case .ident("entity") = current else {
            throw ParserError.unexpectedToken(current, expected: "entity", at: loc())
        }
        advance()
        try expect(.lPar)
        let (domain, alias) = try readSegmentsUntilRPar()
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    func parseAccountPath() throws -> AccountPath {
        guard case .ident("account") = current else {
            throw ParserError.unexpectedToken(current, expected: "account", at: loc())
        }
        advance()
        try expect(.lPar)
        let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
        return AccountPath(segments: segs)
    }

    func parseEntityGroup(flexible: Bool) throws -> EntityPath {
        if flexible, case .ident("entity") = current { return try parseEntityPath() }
        try expect(.lPar)
        let (domain, alias) = try readSegmentsUntilRPar()
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    func parseAccountGroup(flexible: Bool) throws -> AccountPath {
        if flexible, case .ident("account") = current { return try parseAccountPath() }
        switch current {
        case let .number(n):
            advance()
            return AccountPath(segments: ["\(n)"])
        case .lPar:
            try expect(.lPar)
            let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
            return AccountPath(segments: segs)
        default:
            throw ParserError.unexpectedToken(current, expected: "number or (account.path)", at: loc())
        }
    }

    func parseDateBlock() throws -> Date {
        try expect(.lBrace)
        var comps = DateComponents()
        while current != .rBrace {
            switch current {
            case .keyword("year"):
                try expect(.keyword("year")); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                comps.year = (n as NSDecimalNumber).intValue; advance()

            case .keyword("month"):
                try expect(.keyword("month")); try expect(.equals)
                if case let .ident(s) = current {
                    comps.month = monthIndex(from: s); advance()
                } else if case let .number(n) = current {
                    comps.month = (n as NSDecimalNumber).intValue; advance()
                } else {
                    throw ParserError.unexpectedToken(current, expected: "identifier or number", at: loc())
                }

            case .keyword("day"):
                try expect(.keyword("day")); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                comps.day = (n as NSDecimalNumber).intValue; advance()

            default:
                throw ParserError.unexpectedToken(current, expected: "year, month, or day", at: loc())
            }
        }
        try expect(.rBrace)
        return Calendar.current.date(from: comps) ?? Date()
    }

    func monthIndex(from m: String) -> Int {
        let lower = m.lowercased()
        let names = Calendar.current.monthSymbols.map { $0.lowercased() }
        if let idx = names.firstIndex(of: lower) { return idx + 1 }
        let abbr = Calendar.current.shortMonthSymbols.map { $0.lowercased() }
        if let idx = abbr.firstIndex(of: lower) { return idx + 1 }
        return Int(lower) ?? 1
    }
}
