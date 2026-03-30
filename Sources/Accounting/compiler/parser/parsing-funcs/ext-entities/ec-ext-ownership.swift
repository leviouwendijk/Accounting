import Foundation

public extension EntryCompilerParsing {
    /// ownership {
    ///   [effective_date|date] (= YYYY-MM-DD | { year/month/day })
    ///   [percentage] (= NUMBER)
    ///   change { effective_date|date …; percentage … }*
    /// }
    /// correction:
    /// ownership {
    ///     rollforward {
    ///         change {
    ///             ...
    ///         }
    ///     }
    /// Stored as:
    ///   ownership.initial.date / ownership.initial.pct
    ///   ownership.<idx>.date / ownership.<idx>.pct
    @inlinable
    func parseOwnershipBlock(into meta: inout [String:String], tz: TimeZone = .current) -> Bool {
        guard current == .keyword("ownership") || current == .ident("ownership") else { return false }
        advance(); try? beginBlock()

        // --- ownership-scope fields (before any `change`)
        var initialDateStr: String?
        var initialPctStr:  String?

        while current != .rBrace && current != .eof {
            // // stop pre-scan when we hit the first `change` block
            // if current == .ident("change") || current == .keyword("change") { break }

            switch current {
            case .ident("effective_date"), .keyword("effective_date"),
                 .ident("date"),           .keyword("date"):
                if let (_, spec) = try? parseNamedDateOrInferExpecting(
                    names: ["effective_date","date"], tz: tz, allowInfer: false
                ) {
                    if let d = try? spec.asAbsolute(loc: loc()) {
                        initialDateStr = ISO8601DateFormatter().string(from: d)
                    }
                }

            case .ident("percentage"), .keyword("percentage"):
                advance(); if current == .equals { advance() }
                if case let .number(n) = current { initialPctStr = "\(n)"; advance() }

            default:
                // nothing else allowed at ownership top-level here; stop pre-scan
                break
            }

            // If we just consumed something valid, loop; otherwise stop to avoid spins
            if !(current == .ident("effective_date") || current == .keyword("effective_date")
                || current == .ident("date") || current == .keyword("date")
                || current == .ident("percentage") || current == .keyword("percentage")) {
                break
            }
        }

        // // --- rollforward changes
        // var idx = 0
        // while current != .rBrace && current != .eof {
        //     guard current == .ident("change") || current == .keyword("change") else { break }
        //     advance(); try? beginBlock()

        //     var dateStr: String?
        //     var pct: String?

        //     while current != .rBrace && current != .eof {
        //         switch current {
        //         case .ident("effective_date"), .keyword("effective_date"),
        //              .ident("date"),           .keyword("date"):
        //             if let (_, spec) = try? parseNamedDateOrInferExpecting(
        //                 names: ["effective_date","date"], tz: tz, allowInfer: false
        //             ) {
        //                 if let d = try? spec.asAbsolute(loc: loc()) {
        //                     dateStr = ISO8601DateFormatter().string(from: d)
        //                 }
        //             }

        //         case .ident("percentage"), .keyword("percentage"):
        //             advance(); if current == .equals { advance() }
        //             if case let .number(n) = current { pct = "\(n)"; advance() }

        //         default:
        //             break
        //         }
        //     }

        //     _ = try? endBlock()
        //     if let d = dateStr { meta["ownership.\(idx).date"] = d }
        //     if let p = pct     { meta["ownership.\(idx).pct"]  = p }
        //     idx += 1
        // }

        // persist ownership-scope fields
        if let d = initialDateStr { meta["ownership.initial.date"] = d }
        if let p = initialPctStr  { meta["ownership.initial.pct"]  = p }

        _ = try? endBlock()
        return true
    }

    @inlinable
    func parseOwnershipRollforward(
        into meta: inout [String:String],
        tz: TimeZone = .current
    ) throws -> Bool {
        guard current == .keyword("rollforward") || current == .ident("rollforward") else {
            return false
        }

        advance()
        try expect(.lBrace)

        var idx = 0
        while current != .rBrace && current != .eof {
            guard current == .keyword("change") || current == .ident("change") else {
                throw ParserError.unexpectedToken(
                    current,
                    expected: "change",
                    at: loc()
                )
            }

            advance()
            try expect(.lBrace)

            var dateISO: String?
            var pctStr: String?
            var reason: String?
            var divideEntries: [(owner: EntityRef, percent: Decimal)] = []

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("effective_date"), .ident("effective_date"),
                     .keyword("date"), .ident("date"):
                    let (_, spec) = try parseNamedDateOrInferExpecting(
                        names: ["effective_date", "date"],
                        tz: tz,
                        allowInfer: false
                    )
                    let d = try spec.asAbsolute(loc: loc())
                    dateISO = ISO8601DateFormatter().string(from: d)

                case .keyword("percentage"), .ident("percentage"):
                    advance()
                    if current == .equals {
                        advance()
                    }

                    guard case let .number(n) = current else {
                        throw ParserError.unexpectedToken(
                            current,
                            expected: "number",
                            at: loc()
                        )
                    }

                    pctStr = "\(n)"
                    advance()

                case .keyword("details"), .ident("details"),
                     .keyword("reason"), .ident("reason"):
                    reason = try parseFreeTextBlock(named: "details")

                case .keyword("divide"), .ident("divide"):
                    divideEntries = try parseOwnershipDivideBlock()

                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "effective_date/date/percentage/details/reason/divide or '}'",
                        at: loc()
                    )
                }
            }

            try expect(.rBrace)

            if let d = dateISO {
                meta["ownership.\(idx).date"] = d
            }

            if let p = pctStr {
                meta["ownership.\(idx).pct"] = p
            }

            if let r = reason {
                meta["ownership.\(idx).reason"] = r
            }

            for (divideIndex, entry) in divideEntries.enumerated() {
                meta["ownership.\(idx).divide.\(divideIndex).owner"] = entry.owner.printable
                meta["ownership.\(idx).divide.\(divideIndex).pct"] = "\(entry.percent)"
            }

            idx += 1
        }

        try expect(.rBrace)
        return true
    }

    @inlinable
    func parseOwnershipDivideBlock() throws -> [(owner: EntityRef, percent: Decimal)] {
        switch current {
        case .keyword("divide"), .ident("divide"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "divide",
                at: loc()
            )
        }

        try expect(.lBrace)

        var out: [(owner: EntityRef, percent: Decimal)] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("to"), .ident("to"),
                 .keyword("owner"), .ident("owner"):
                out.append(
                    try parseOwnershipDivideEntry()
                )

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "to(...) = <number> or owner.path(<number>)",
                    at: loc()
                )
            }
        }

        try expect(.rBrace)
        return out
    }

    @inlinable
    func parseOwnershipDivideEntry() throws -> (owner: EntityRef, percent: Decimal) {
        switch current {
        case .keyword("to"), .ident("to"):
            advance()
            try expect(.lPar)

            let owner = try parseEntityRefFlexible()

            try expect(.rPar)
            try expect(.equals)

            let percent = try expectDecimal()

            return (owner: owner, percent: percent)

        default:
            let owner = try parseEntityRefFlexible()

            try expect(.lPar)
            let percent = try expectDecimal()
            try expect(.rPar)

            return (owner: owner, percent: percent)
        }
    }

    // @inlinable
    // func parseOwnershipRollforward(
    //     into meta: inout [String:String],
    //     tz: TimeZone = .current
    // ) throws -> Bool {
    //     guard current == .keyword("rollforward") || current == .ident("rollforward") else { return false }
    //     advance(); try expect(.lBrace)

    //     var idx = 0
    //     while current != .rBrace && current != .eof {
    //         guard current == .keyword("change") || current == .ident("change") else {
    //             throw ParserError.unexpectedToken(current, expected: "change", at: loc())
    //         }
    //         advance(); try expect(.lBrace)

    //         var dateISO: String?
    //         var pctStr:  String?
    //         var reason:  String?

    //         while current != .rBrace && current != .eof {
    //             switch current {
    //             case .keyword("effective_date"), .ident("effective_date"),
    //                  .keyword("date"),           .ident("date"):
    //                 let (_, spec) = try parseNamedDateOrInferExpecting(
    //                     names: ["effective_date","date"], tz: tz, allowInfer: false
    //                 )
    //                 let d = try spec.asAbsolute(loc: loc())
    //                 dateISO = ISO8601DateFormatter().string(from: d)

    //             case .keyword("percentage"), .ident("percentage"):
    //                 advance(); if current == .equals { advance() }
    //                 guard case let .number(n) = current else {
    //                     throw ParserError.unexpectedToken(current, expected: "number", at: loc())
    //                 }
    //                 pctStr = "\(n)"; advance()

    //             case .keyword("details"), .ident("details"),
    //                  .keyword("reason"),  .ident("reason"):
    //                 reason = try parseFreeTextBlock(named: "details")

    //             default:
    //                 throw ParserError.unexpectedToken(
    //                     current,
    //                     expected: "effective_date/date/percentage/details or '}'",
    //                     at: loc()
    //                 )
    //             }
    //         }

    //         try expect(.rBrace)

    //         if let d = dateISO { meta["ownership.\(idx).date"]   = d }
    //         if let p = pctStr  { meta["ownership.\(idx).pct"]    = p }
    //         if let r = reason  { meta["ownership.\(idx).reason"] = r }
    //         idx += 1
    //     }

    //     try expect(.rBrace)
    //     return true
    // }
}

