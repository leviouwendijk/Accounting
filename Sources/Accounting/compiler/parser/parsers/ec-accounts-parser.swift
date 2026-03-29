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
        lineMap: [Int]? = nil,
        spanMap: [SourceSpan]? = nil,
        verbose: Bool = false
    ) {
        self.init(
            core: .init(
                tokens: tokens,
                filePath: fileURL?.path,
                lineMap: lineMap,
                spanMap: spanMap,
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
            case .keyword("account"):
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

// // indexing for ec-editor/
// public extension EntryCompilerAccountsFileParser {
//     func parseAccountsFileIndexed() throws -> [ECIndexedAccountDefinition] {
//         core.trace("parsing accounts file indexed: \(fileURL?.lastPathComponent ?? "<memory>")")

//         var out: [ECIndexedAccountDefinition] = []

//         while current != .eof {
//             switch current {
//             case .keyword("account"):
//                 let start = loc()
//                 core.trace("• account override block @ \(start)")

//                 let def = try parseAccountOverrideBlock()

//                 out.append(
//                     ECIndexedAccountDefinition(
//                         def: def,
//                         location: ECDefinitionResult(
//                             file: start.file ?? fileURL?.path ?? "<memory>",
//                             line: start.line,
//                             column: start.column
//                         )
//                     )
//                 )

//             default:
//                 throw ParserError.unexpectedToken(
//                     current,
//                     expected: "account { … }",
//                     at: loc()
//                 )
//             }
//         }

//         return out
//     }
// }

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

            case .keyword("label"):
                label = try parseScalarOrFreeTextField(
                    named: "label"
                )

            // case .keyword("label"):
            //     advance()
            //     if current == .lBrace {
            //         label = try parseFreeTextBlock(named: "label")
            //     } else {
            //         try expect(.equals)
            //         guard case let .string(s) = current else {
            //             throw ParserError.unexpectedToken(current, expected: "string", at: loc())
            //         }
            //         label = s; advance()
            //     }

            case .keyword("direction"):
                advance(); try expect(.equals)
                guard case let .keyword(dc) = current else {
                    throw ParserError.unexpectedToken(current, expected: "debit|credit|dr|cr", at: loc())
                }
                direction = try Direction(raw: dc); advance()

            case .keyword("level"):
                advance(); try expect(.equals)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number", at: loc())
                }
                level = (n as NSDecimalNumber).intValue; advance()

            case .keyword("identifiers"):
                identifiers = try parseAccountIdentifiersBlock()

            case .keyword("applicability"):
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
        if case .keyword("identifiers") = current { advance() }
        else if case .ident("identifiers") = current { advance() }
        else {
            throw ParserError.unexpectedToken(current, expected: "identifiers", at: loc())
        }
        try beginBlock()

        var rgs: String?
        var oms: String?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("rgs"), .ident("rgs"):
                advance(); try expect(.equals)
                switch current {
                case let .ident(s), let .keyword(s), let .string(s):
                    rgs = s; advance()
                default:
                    throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }

            case .keyword("omslag"), .ident("omslag"):
                advance(); try expect(.equals)
                switch current {
                case let .ident(s), let .keyword(s), let .string(s):
                    oms = s; advance()
                default:
                    throw ParserError.unexpectedToken(current, expected: "identifier|string", at: loc())
                }

            default:
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
