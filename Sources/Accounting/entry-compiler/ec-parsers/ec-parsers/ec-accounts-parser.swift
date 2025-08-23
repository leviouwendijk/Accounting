import Foundation

// Parses project config account overrides:
// account { use code 10201 ... }
public final class EntryCompilerAccountsFileParser: EntryCompilerParsing {
    public var core: EntryCompilerParserCore
    public init(core: EntryCompilerParserCore) { self.core = core }
    public convenience init(tokens: [EntryCompilerToken]) { self.init(core: .init(tokens: tokens)) }

    public func parseAccountsFile() throws -> [AccountDef] {
        var out: [AccountDef] = []
        while current != .eof {
            switch current {
            case .keyword("account"):
                out.append(try parseAccountOverrideBlock())
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

            case .ident("label"):
                advance()
                if current == .lBrace {
                    try beginBlock()
                    guard case let .string(s) = current else {
                        throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                    }
                    label = s; advance()
                    try endBlock()
                } else {
                    try expect(.equals)
                    guard case let .string(s) = current else {
                        throw ParserError.unexpectedToken(current, expected: "string", at: loc())
                    }
                    label = s; advance()
                }

            case .ident("direction"):
                advance(); try expect(.equals)
                guard case let .ident(dc) = current else {
                    throw ParserError.unexpectedToken(current, expected: "debit|credit|dr|cr", at: loc())
                }
                direction = try Direction(raw: dc); advance()

            case .ident("level"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                level = (n as NSDecimalNumber).intValue; advance()

            case .ident("identifiers"):
                identifiers = try parseAccountIdentifiersBlock()

            case .ident("applicability"):
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
        try expect(.ident("identifiers")); try beginBlock()
        var rgs: String?
        var oms: String?

        while current != .rBrace && current != .eof {
            if case .ident("rgs") = current {
                advance(); try expect(.equals)
                if case let .ident(s) = current { rgs = s; advance() }
                else if case let .string(x) = current { rgs = x; advance() }
                else {
                    throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }
            } else if case .ident("omslag") = current {
                advance(); try expect(.equals)
                if case let .ident(s) = current { oms = s; advance() }
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
        try expect(.ident("applicability")); try beginBlock()
        var zzp = "", ez = "", bv = "", svc = "", branche = ""

        while current != .rBrace && current != .eof {
            switch current {
            case .ident("zzp"):     try expectFieldEquals("zzp");     zzp = try expectIdentValue()
            case .ident("ez"):      try expectFieldEquals("ez");      ez = try expectIdentValue()
            case .ident("bv"):      try expectFieldEquals("bv");      bv = try expectIdentValue()
            case .ident("svc"):     try expectFieldEquals("svc");     svc = try expectIdentValue()
            case .ident("branche"): try expectFieldEquals("branche"); branche = try expectIdentValue()
            default:
                throw ParserError.unexpectedToken(current, expected: "zzp/ez/bv/svc/branche", at: loc())
            }
        }
        try endBlock()
        return Applicability(zzp: zzp, ez: ez, bv: bv, svc: svc, branche: branche)
    }
}
