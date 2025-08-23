import Foundation

// Parses project config account overrides:
// account { use code 10201 ... }
public final class EntryCompilerAccountsFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    private let fileURL: URL?

    public init(core: EntryCompilerParserCore, fileURL: URL? = nil) {
        self.core = core
        self.fileURL = fileURL
    }
    public convenience init(
        tokens: [EntryCompilerToken],
        fileURL: URL? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(
                tokens: tokens,
                filePath: fileURL?.path,
                verbose: verbose
            ),
            fileURL: fileURL
        )
    }

    public func parseAccountsFile() throws -> [AccountDef] {
        core.trace("parsing accounts file: \(fileURL?.lastPathComponent ?? "<memory>")")
        var out: [AccountDef] = []
        while current != .eof {
            switch current {
            case .keyword("account"), .ident("account"):
                core.trace("• account override block @ \(loc())")
                let def = try parseAccountOverrideBlock()
                out.append(def)
                core.trace("  → \(def.code) \(def.label.map { "“\($0)”" } ?? "")")
            default:
                throw ParserError.unexpectedToken(current, expected: "account { … }", at: loc())
            }
        }
        return out
    }
}

public extension EntryCompilerParsing {
    @inlinable
    func parseAccountOverrideBlock() throws -> AccountDef {
        try expectKeyword("account"); try beginBlock()

        var code: String?
        var label: String?
        var direction: Direction?
        var level: Int?
        var identifiers: RGSIdentifiers?
        var applicability: Applicability?

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("use"):
                advance()
                try expectKeyword("code")
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number (account code)", at: loc())
                }
                code = String((n as NSDecimalNumber).intValue); advance()

            case .keyword("label"), .ident("label"):
                advance()
                if current == .lBrace {
                    label = try parseFreeTextBlock(named: "label")
                } else {
                    try expect(.equals)
                    guard case let .string(s) = current else {
                        throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                    }
                    label = s; advance()
                }

            case .keyword("direction"), .ident("direction"):
                advance(); try expect(.equals)
                guard case let .keyword(dc) = current else {
                    throw ParserError.unexpectedToken(current, expected: "debit|credit|dr|cr", at: loc())
                }
                direction = try Direction(raw: dc); advance()

            case .keyword("level"), .ident("level"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                level = (n as NSDecimalNumber).intValue; advance()

            case .keyword("identifiers"), .ident("identifiers"):
                identifiers = try parseAccountIdentifiersBlock()

            case .keyword("applicability"), .ident("applicability"):
                applicability = try parseApplicabilityBlock()

            default:
                throw ParserError.unexpectedToken(current, expected: "use/label/direction/level/identifiers/applicability", at: loc())
            }
        }

        try endBlock()
        guard let codeStr = code else {
            throw ParserError.unexpectedToken(current, expected: "use code <number>", at: loc())
        }
        return AccountDef(code: codeStr, label: label, direction: direction, level: level, identifiers: identifiers, applicability: applicability)
    }

    @inlinable
    func parseAccountIdentifiersBlock() throws -> RGSIdentifiers {
        try expect(.keyword("identifiers"))
        try beginBlock()
        var rgs: String?
        var oms: String?

        while current != .rBrace && current != .eof {
            if case .keyword("rgs") = current {
                advance(); try expect(.equals)
                if case let .keyword(s) = current { rgs = s; advance() }
                else if case let .string(x) = current { rgs = x; advance() }
                else {
                    throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }
            } else if case .keyword("omslag") = current {
                advance(); try expect(.equals)
                if case let .keyword(s) = current { oms = s; advance() }
                else if case let .string(s) = current { oms = s; advance() }
                else { throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc()) }
            } else {
                throw ParserError.unexpectedToken(current, expected: "rgs or omslag", at: loc())
            }
        }
        try endBlock()
        return RGSIdentifiers(rgs: rgs ?? "", omslag: oms)
    }

    @inlinable
    func parseApplicabilityBlock() throws -> Applicability {
        if case .ident("applicability") = current { advance() }
        else if case .keyword("applicability") = current { advance() }
        else { try expect(.ident("applicability")) } // fallback; will error nicely
        try beginBlock()

        var zzp = "", ez = "", bv = "", svc = "", branche = ""

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("zzp"), .keyword("zzp"):
                try expectFieldEquals("zzp"); zzp = try expectNameOrNumberValue()
            case .ident("ez"), .keyword("ez"):
                try expectFieldEquals("ez");  ez  = try expectNameOrNumberValue()
            case .ident("bv"), .keyword("bv"):
                try expectFieldEquals("bv");  bv  = try expectNameOrNumberValue()
            case .ident("svc"), .keyword("svc"):
                try expectFieldEquals("svc"); svc = try expectNameOrNumberValue()
            case .ident("branche"), .keyword("branche"):
                try expectFieldEquals("branche"); branche = try expectNameOrNumberValue()
            default:
                throw ParserError.unexpectedToken(current, expected: "zzp/ez/bv/svc/branche", at: loc())
            }
        }

        try endBlock()
        return Applicability(zzp: zzp, ez: ez, bv: bv, svc: svc, branche: branche)
    }
}
