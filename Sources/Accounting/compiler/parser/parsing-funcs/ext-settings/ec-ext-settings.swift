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
        var equity: StatementEquitySettings?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("company"), .ident("company"):
                company = try parseStatementCompanySettings()

            case .keyword("equity"), .ident("equity"):
                equity = try parseStatementEquitySettings()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "company or equity",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementDataSettings(
            company: company,
            equity: equity
        )
    }

    func parseStatementEquitySettings() throws -> StatementEquitySettings {
        switch current {
        case .keyword("equity"), .ident("equity"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "equity",
                at: loc()
            )
        }

        try beginBlock()

        var preset: String?
        var views: [StatementEquityViewSettings] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("preset"), .ident("preset"):
                advance()
                try expect(.equals)
                preset = try expectNameOrNumberValue()

            case .keyword("view"), .ident("view"):
                views.append(
                    try parseStatementEquityViewSettings()
                )

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "preset or view",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementEquitySettings(
            preset: preset,
            views: views
        )
    }

    func parseStatementEquityViewSettings() throws -> StatementEquityViewSettings {
        switch current {
        case .keyword("view"), .ident("view"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "view",
                at: loc()
            )
        }

        try beginBlock()

        var alias: String?
        var sections: [StatementEquitySectionSettings] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("use"), .ident("use"):
                advance()

                switch current {
                case .keyword("alias"), .ident("alias"):
                    advance()
                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "alias",
                        at: loc()
                    )
                }

                alias = try expectNameOrNumberValue()

            case .keyword("section"), .ident("section"):
                sections.append(
                    try parseStatementEquitySectionSettings()
                )

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "use alias or section",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let alias else {
            throw ParserError.unexpectedToken(
                current,
                expected: "view { use alias <preset> ... }",
                at: loc()
            )
        }

        return StatementEquityViewSettings(
            alias: alias,
            sections: sections
        )
    }

    func parseStatementEquitySectionSettings() throws -> StatementEquitySectionSettings {
        switch current {
        case .keyword("section"), .ident("section"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "section",
                at: loc()
            )
        }

        try beginBlock()

        var kind: StatementEquitySectionSettings.Kind = .rows
        var rows: [StatementEquityRowSettings] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("standard"), .ident("standard"):
                guard rows.isEmpty else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "section { standard } must not be mixed with row declarations",
                        at: loc()
                    )
                }

                guard kind != .standard else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "only one standard marker per section",
                        at: loc()
                    )
                }

                advance()
                kind = .standard

            case .keyword("row"), .ident("row"):
                guard kind == .rows else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "row declarations cannot be mixed with section { standard }",
                        at: loc()
                    )
                }

                rows.append(
                    try parseStatementEquityRowSettings()
                )

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "standard or row",
                    at: loc()
                )
            }
        }

        try endBlock()

        return StatementEquitySectionSettings(
            kind: kind,
            rows: rows
        )
    }

    func parseStatementEquityRowSettings() throws -> StatementEquityRowSettings {
        switch current {
        case .keyword("row"), .ident("row"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "row",
                at: loc()
            )
        }

        switch current {
        case .keyword("split"), .ident("split"):
            advance()

            let owner = try parseStatementEntityPath()
            let percent = try expectDecimal()
            var label: String?
            var includeInSum: Bool?

            if current == .lBrace {
                try beginBlock()

                while current != .rBrace && current != .eof {
                    switch current {
                    case .keyword("label"), .ident("label"):
                        label = try parseScalarOrFreeTextField(
                            named: "label"
                        )

                    case .keyword("include_in_sum"), .ident("include_in_sum"):
                        includeInSum = try parseStatementEquityIncludeInSumValue()

                    default:
                        throw ParserError.unexpectedToken(
                            current,
                            expected: "label or include_in_sum",
                            at: loc()
                        )
                    }
                }

                try endBlock()
            }

            return StatementEquityRowSettings(
                kind: .split,
                owner: owner,
                percent: percent,
                label: label,
                includeInSum: includeInSum
            )

        case .keyword("subtotal"), .ident("subtotal"):
            advance()
            try beginBlock()

            var label: String?
            var includeInSum: Bool?
            var members: [StatementEquityMemberSettings] = []

            while current != .rBrace && current != .eof {
                switch current {
                case .keyword("label"), .ident("label"):
                    label = try parseScalarOrFreeTextField(
                        named: "label"
                    )

                case .keyword("include_in_sum"), .ident("include_in_sum"):
                    includeInSum = try parseStatementEquityIncludeInSumValue()

                case .keyword("member"), .ident("member"):
                    members.append(
                        try parseStatementEquityMemberSettings()
                    )

                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "label, include_in_sum, or member",
                        at: loc()
                    )
                }
            }

            try endBlock()

            return StatementEquityRowSettings(
                kind: .subtotal,
                label: label,
                includeInSum: includeInSum,
                members: members
            )

        default:
            let owner = try parseStatementEntityPath()

            return StatementEquityRowSettings(
                kind: .owner,
                owner: owner
            )
        }
    }

    func parseStatementEquityMemberSettings() throws -> StatementEquityMemberSettings {
        switch current {
        case .keyword("member"), .ident("member"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "member",
                at: loc()
            )
        }

        let owner = try parseStatementEntityPath()
        let percent = try expectDecimal()

        return StatementEquityMemberSettings(
            owner: owner,
            percent: percent
        )
    }

    func parseStatementEntityPath() throws -> StatementEntityPath {
        let ref = try parseEntityRefFlexible()
        return StatementEntityPath(ref: ref)
    }

    func parseStatementEquityIncludeInSumValue() throws -> Bool {
        switch current {
        case .keyword("include_in_sum"), .ident("include_in_sum"):
            advance()
        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "include_in_sum",
                at: loc()
            )
        }

        try expect(.equals)

        switch current {
        case .keyword("true"), .ident("true"):
            advance()
            return true

        case .keyword("false"), .ident("false"):
            advance()
            return false

        case .string(let s):
            let lowered = s.lowercased()
            advance()

            if lowered == "true" || lowered == "yes" || lowered == "1" {
                return true
            }

            if lowered == "false" || lowered == "no" || lowered == "0" {
                return false
            }

            throw ParserError.unexpectedToken(
                current,
                expected: "boolean value",
                at: loc()
            )

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "boolean value",
                at: loc()
            )
        }
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
