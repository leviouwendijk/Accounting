import Foundation

public final class ECDocumentFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public let defaultTZ: TimeZone
    private let fileURL: URL?

    public init(
        core: EntryCompilerParserCore,
        defaultTimeZone: TimeZone,
        fileURL: URL? = nil
    ) {
        self.core = core
        self.defaultTZ = defaultTimeZone
        self.fileURL = fileURL
    }

    public convenience init(
        tokens: [EntryCompilerToken],
        defaultTimeZone: TimeZone,
        fileURL: URL? = nil,
        lineMap: [Int]? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(
                tokens: tokens,
                filePath: fileURL?.path,
                lineMap: lineMap,
                verbose: verbose
            ),
            defaultTimeZone: defaultTimeZone,
            fileURL: fileURL
        )
    }

    public func parseDocumentsFile() throws -> [ECDocument] {
        var out: [ECDocument] = []

        while current != .eof {
            let before = core.index

            switch current {
            case .keyword("document"), .ident("document"):
                out.append(try parseDocument())

            default:
                advance()
            }

            if core.index == before {
                throw ParserError.unexpectedToken(
                    current,
                    expected: "document block or parser progress",
                    at: loc()
                )
            }
        }

        return out
    }

    private func parseDocument() throws -> ECDocument {
        try expectKeywordLike("document")
        try beginBlock()

        var id: String?
        var kind: ECDocumentKind?
        var title: String?
        var recipient: String?
        var subjectPrefix: String?
        var senderName: String?
        var senderRole: String?
        var date: Date?
        var periods: [String] = []
        var footerLines: [String] = []
        var administratorLines: [String] = []
        var blocks: [ECDocumentBlock] = []
        var assets: ECDocumentAssets?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("id"), .keyword("id"):
                try expectFieldEquals("id")
                id = try parseScalarStringLike()

            case .ident("kind"), .keyword("kind"):
                try expectFieldEquals("kind")
                let raw = try parseScalarStringLike()

                guard let parsed = ECDocumentKind(rawValue: raw) else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "known document kind",
                        at: loc()
                    )
                }

                kind = parsed

            case .ident("title"), .keyword("title"):
                try expectFieldEquals("title")
                title = try parseScalarStringLike()

            case .ident("recipient"), .keyword("recipient"):
                try expectFieldEquals("recipient")
                recipient = try parseScalarStringLike()

            case .ident("subject_prefix"), .keyword("subject_prefix"):
                try expectFieldEquals("subject_prefix")
                subjectPrefix = try parseScalarStringLike()

            case .ident("sender_name"), .keyword("sender_name"):
                try expectFieldEquals("sender_name")
                senderName = try parseScalarStringLike()

            case .ident("sender_role"), .keyword("sender_role"):
                try expectFieldEquals("sender_role")
                senderRole = try parseScalarStringLike()

            case .ident("date"), .keyword("date"):
                try expectFieldEquals("date")
                date = try parseAbsoluteDate()

            case .ident("assets"), .keyword("assets"):
                assets = try parseAssets()

            case .ident("periods"), .keyword("periods"):
                periods = try parseStringListBlock(named: "periods")

            case .ident("footer_lines"), .keyword("footer_lines"):
                footerLines = try parseStringListBlock(named: "footer_lines")

            case .ident("administrator_lines"), .keyword("administrator_lines"):
                administratorLines = try parseStringListBlock(named: "administrator_lines")

            case .ident("section"), .keyword("section"):
                blocks.append(.section(try parseSection()))

            case .ident("signature"), .keyword("signature"):
                blocks.append(.signature(try parseSignature()))

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "document field or child block",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let finalID = id else {
            throw ParserError.unexpectedToken(
                current,
                expected: "document id",
                at: loc()
            )
        }

        guard let finalKind = kind else {
            throw ParserError.unexpectedToken(
                current,
                expected: "document kind",
                at: loc()
            )
        }

        return ECDocument(
            id: finalID,
            kind: finalKind,
            title: title,
            recipient: recipient,
            subjectPrefix: subjectPrefix,
            senderName: senderName,
            senderRole: senderRole,
            date: date,
            periods: periods,
            footerLines: footerLines,
            administratorLines: administratorLines,
            blocks: blocks,
            assets: assets
        )
    }

    private func parseSection() throws -> ECDocumentSection {
        try expectKeywordLike("section")
        try beginBlock()

        var header: String?
        var paragraphs: [String] = []
        var template: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("header"), .keyword("header"):
                try expectFieldEquals("header")
                header = try parseScalarStringLike()

            case .ident("paragraph"), .keyword("paragraph"):
                try expectFieldEquals("paragraph")
                paragraphs.append(try parseScalarStringLike())

            case .ident("template"), .keyword("template"):
                try expectFieldEquals("template")
                template = try parseScalarStringLike()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "header, paragraph or template",
                    at: loc()
                )
            }
        }

        try endBlock()

        return ECDocumentSection(
            header: header,
            paragraphs: paragraphs,
            template: template
        )
    }

    private func parseAssets() throws -> ECDocumentAssets {
        try expectKeywordLike("assets")
        try beginBlock()

        var signatureImagePath: String?
        var signatureSymbol: String?
        var logoSymbol: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("signature_image_path"), .keyword("signature_image_path"):
                try expectFieldEquals("signature_image_path")
                signatureImagePath = try parseScalarStringLike()

            case .ident("signature_symbol"), .keyword("signature_symbol"):
                try expectFieldEquals("signature_symbol")
                signatureSymbol = try parseScalarStringLike()

            case .ident("logo_symbol"), .keyword("logo_symbol"):
                try expectFieldEquals("logo_symbol")
                logoSymbol = try parseScalarStringLike()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "signature_image_path, signature_symbol or logo_symbol",
                    at: loc()
                )
            }
        }

        try endBlock()

        let resolvedSignatureImagePath = signatureImagePath ?? signatureSymbol

        _ = logoSymbol

        return ECDocumentAssets(
            signatureImagePath: resolvedSignatureImagePath
        )
    }

    private func parseSignature() throws -> ECDocumentSignatureBlock {
        try expectKeywordLike("signature")
        try beginBlock()

        var includeSignatureImage = true
        var includeDate = true

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("include_image"), .keyword("include_image"):
                try expectFieldEquals("include_image")
                includeSignatureImage = try parseBoolLike()

            case .ident("include_date"), .keyword("include_date"):
                try expectFieldEquals("include_date")
                includeDate = try parseBoolLike()

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "include_image or include_date",
                    at: loc()
                )
            }
        }

        try endBlock()

        return ECDocumentSignatureBlock(
            includeSignatureImage: includeSignatureImage,
            includeDate: includeDate
        )
    }

    private func parseStringListBlock(named name: String) throws -> [String] {
        try expectKeywordLike(name)
        try beginBlock()

        var out: [String] = []

        while current != .rBrace && current != .eof {
            out.append(try parseScalarStringLike())
        }

        try endBlock()
        return out
    }

    private func parseScalarStringLike() throws -> String {
        switch current {
        case let .string(s):
            advance()
            return s

        case let .ident(s):
            advance()
            return s

        case let .keyword(s):
            advance()
            return s

        case let .dateLiteral(s):
            advance()
            return s

        case let .number(n):
            advance()
            return NSDecimalNumber(decimal: n).stringValue

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "string-like scalar",
                at: loc()
            )
        }
    }

    private func parseAbsoluteDate() throws -> Date {
        let raw: String

        switch current {
        case let .dateLiteral(s):
            raw = s
            advance()

        case let .string(s):
            raw = s
            advance()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "date literal",
                at: loc()
            )
        }

        let df = ISO8601DateFormatter()
        df.formatOptions = [.withFullDate]

        guard let date = df.date(from: raw) else {
            throw ParserError.unexpectedToken(
                current,
                expected: "valid YYYY-MM-DD date",
                at: loc()
            )
        }

        return date
    }

    private func parseBoolLike() throws -> Bool {
        switch current {
        case .ident("true"), .keyword("true"):
            advance()
            return true

        case .ident("false"), .keyword("false"):
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

    private func expectKeywordLike(_ keyword: String) throws {
        switch current {
        case .keyword(keyword), .ident(keyword):
            advance()

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: keyword,
                at: loc()
            )
        }
    }
}
