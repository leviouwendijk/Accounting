import Foundation

public extension EntryCompilerParsing {
    func parseTimeZoneValue() throws -> TimeZone {
        guard case let .ident(s) = current else {
            throw ParserError.unexpectedToken(current, expected: "timezone identifier", at: loc())
        }
        // IANA
        if let tz = TimeZone(identifier: s) {
            advance()
            return tz
        }

        throw ParserError.unexpectedToken(current, expected: "IANA tz", at: loc())
    }

    func parseEntrySettings() throws -> EntrySettings {
        try expectKeyword("entry"); try beginBlock()

        var tz: TimeZone?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("default_timezone"), .keyword("default_timezone"):
                advance(); try expect(.equals)
                let parsedTZ = try parseTimeZoneValue() // supports IANA
                tz = parsedTZ
            default:
                throw ParserError.unexpectedToken(current, expected: "default_timezone", at: loc())
            }
        }

        try endBlock()
        guard let finalTZ = tz else {
            throw ParserError.unexpectedToken(current, expected: "default_timezone", at: loc())
        }
        return EntrySettings(defaultTimezone: finalTZ)
    }

    func parseAggregationSettings() throws -> AggregationSettings {
        try expectKeyword("aggregation"); try beginBlock()

        var includePrev: Bool?
        var chartFind: String?
        var chartVersion: ChartVersion?

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("include_previous_periods"), .ident("include_previous_periods"):
                advance(); try expect(.equals)
                includePrev = try parseBoolValue()

            case .keyword("chart"):
                let parsed = try parseChartBlock()
                chartFind = parsed.find
                chartVersion = parsed.version

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "include_previous_periods or chart",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let ip = includePrev else {
            throw ParserError.unexpectedToken(current, expected: "include_previous_periods", at: loc())
        }
        guard let cf = chartFind, let cv = chartVersion else {
            throw ParserError.unexpectedToken(current, expected: "chart { find <ident> version { major minor } }", at: loc())
        }

        return AggregationSettings(
            includePreviousPeriods: ip,
            chartFind: cf,
            chartVersion: cv
        )
    }

    func parseStatementDataSettings() throws -> StatementDataSettings {
        switch current {
        case .keyword("statement_data"), .ident("statement_data"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "statement_data",
                at: loc()
            )
        }

        try beginBlock()

        var company: StatementCompanySettings?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("company"), .ident("company"):
                company = try parseStatementCompanySettings()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "company",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementDataSettings(company: company)
    }

    func parseStatementCompanySettings() throws -> StatementCompanySettings {
        switch current {
        case .keyword("company"), .ident("company"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "company",
                at: loc()
            )
        }

        try beginBlock()

        var name: String?
        var legalForm: String?
        var kvk: String?
        var rsin: String?
        var btw: String?
        var address: StatementCompanyAddressSettings?
        var contact: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("name"), .ident("name"):
                advance()
                try expect(.equals)
                name = try parseOptionalStringValue()

            case .keyword("legal_form"), .ident("legal_form"):
                advance()
                try expect(.equals)
                legalForm = try parseOptionalStringValue()

            case .keyword("kvk"), .ident("kvk"):
                advance()
                try expect(.equals)
                kvk = try parseOptionalStringValue()

            case .keyword("rsin"), .ident("rsin"):
                advance()
                try expect(.equals)
                rsin = try parseOptionalStringValue()

            case .keyword("btw"), .ident("btw"):
                advance()
                try expect(.equals)
                btw = try parseOptionalStringValue()

            case .keyword("address"), .ident("address"):
                address = try parseStatementCompanyAddressSettings()

            case .keyword("contact"), .ident("contact"):
                advance()
                try expect(.equals)
                contact = try parseOptionalStringValue()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "name, legal_form, kvk, rsin, btw, address, or contact",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementCompanySettings(
            name: name,
            legalForm: legalForm,
            kvk: kvk,
            rsin: rsin,
            btw: btw,
            address: address,
            contact: contact
        )
    }

    func parseStatementCompanyAddressSettings() throws -> StatementCompanyAddressSettings {
        switch current {
        case .keyword("address"), .ident("address"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "address",
                at: loc()
            )
        }

        try beginBlock()

        var street: String?
        var number: String?
        var areaCode: String?
        var city: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("street"), .ident("street"):
                advance()
                try expect(.equals)
                street = try parseOptionalStringValue()

            case .keyword("number"), .ident("number"):
                advance()
                try expect(.equals)
                number = try parseOptionalStringValue()

            case .keyword("area_code"), .ident("area_code"):
                advance()
                try expect(.equals)
                areaCode = try parseOptionalStringValue()

            case .keyword("city"), .ident("city"):
                advance()
                try expect(.equals)
                city = try parseOptionalStringValue()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "street, number, area_code, or city",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementCompanyAddressSettings(
            street: street,
            number: number,
            areaCode: areaCode,
            city: city
        )
    }

    func parseOptionalStringValue() throws -> String? {
        switch current {
        case .ident("nil"), .keyword("nil"):
            advance()
            return nil

        case let .string(s):
            advance()
            return s

        case let .ident(s):
            advance()
            return s

        case let .keyword(s):
            advance()
            return s

        case let .number(n):
            advance()
            return "\(n)"

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "string|identifier|number|nil",
                at: loc()
            )
        }
    }
}
