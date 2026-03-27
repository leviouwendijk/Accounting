import Foundation

public struct EntryCompilerLexer: EntryCompilerLexing, Sendable {
    public let scalars: [UnicodeScalar]
    public var index: Int = 0

    public var detailsState: EntryCompilerDetailsState = .none
    public var referenceState: EntryCompilerReferenceState = .none

    public var line: Int = 1
    public var column: Int = 1

    public var lastConsumedLine: Int = 1
    public var lastConsumedColumn: Int = 0

    public var diagnostics: [EntryCompilerLexDiagnostic] = []
    public var lastTokenSpan: SourceSpan?

    public let lexingSets: EntryCompilerLexingSets

    private let stringKeywordSet: Set<String>

    public init(
        source: String,
        flavor: EntryCompilerLexingFlavor
    ) {
        self.scalars = Array(source.unicodeScalars)
        self.lexingSets = EntryCompilerLexingSetsCache.pointer(for: flavor)

        switch flavor {
        case .entries, .transactions:
            self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

        case .settings, .accounts, .entities, .string, .fallback:
            self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

        case .documents:
            self.stringKeywordSet = []
        }
    }

    private mutating func span(
        startLine: Int,
        startColumn: Int,
        endLine: Int,
        endColumn: Int
    ) -> SourceSpan {
        SourceSpan(
            start: SourceLocation(line: startLine, column: startColumn),
            end: SourceLocation(line: endLine, column: endColumn)
        )
    }

    private mutating func emitToken(
        _ token: EntryCompilerToken,
        startLine: Int,
        startColumn: Int
    ) -> EntryCompilerToken {
        let consumedAfterStart =
            (lastConsumedLine > startLine)
            || (lastConsumedLine == startLine && lastConsumedColumn >= startColumn)

        let endLine = consumedAfterStart ? lastConsumedLine : startLine
        let endColumn = consumedAfterStart ? lastConsumedColumn : startColumn

        lastTokenSpan = span(
            startLine: startLine,
            startColumn: startColumn,
            endLine: endLine,
            endColumn: endColumn
        )

        return token
    }

    private mutating func emitEOF() -> EntryCompilerToken {
        lastTokenSpan = span(
            startLine: line,
            startColumn: column,
            endLine: line,
            endColumn: column
        )

        return .eof
    }

    private mutating func appendDiagnostic(
        severity: EntryCompilerLexDiagnosticSeverity = .error,
        kind: EntryCompilerLexDiagnosticKind,
        message: String,
        startLine: Int,
        startColumn: Int,
        endLine: Int? = nil,
        endColumn: Int? = nil,
        lexeme: String? = nil
    ) {
        let span = SourceSpan(
            start: SourceLocation(line: startLine, column: startColumn),
            end: SourceLocation(
                line: endLine ?? startLine,
                column: endColumn ?? startColumn
            )
        )

        diagnostics.append(
            EntryCompilerLexDiagnostic(
                severity: severity,
                kind: kind,
                message: message,
                span: span,
                lexeme: lexeme
            )
        )
    }

    public mutating func nextToken() -> EntryCompilerToken {
        lastTokenSpan = nil

        while true {
            if detailsState == .awaitingContent {
                let startLine = line
                let startColumn = column

                let result = readUntilClosingBraceVerbatimResult()

                if result.terminated {
                    detailsState = .awaitingClose
                } else {
                    detailsState = .none
                    appendDiagnostic(
                        kind: .unterminatedBlock,
                        message: "unterminated free-text block",
                        startLine: startLine,
                        startColumn: startColumn,
                        endLine: lastConsumedLine,
                        endColumn: max(lastConsumedColumn, startColumn),
                        lexeme: result.text
                    )
                }

                return emitToken(
                    .string(result.text),
                    startLine: startLine,
                    startColumn: startColumn
                )
            }

            skipWhitespaceAndComments()

            let startLine = line
            let startColumn = column

            switch detailsState {
            case .awaitingOpen:
                guard peek() == "{" else {
                    detailsState = .none
                    appendDiagnostic(
                        kind: .missingBlockOpeningBrace,
                        message: "expected '{' after free-text keyword",
                        startLine: startLine,
                        startColumn: startColumn
                    )
                    return emitEOF()
                }

                advance()
                detailsState = .awaitingContent
                return emitToken(
                    .lBrace,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case .awaitingClose:
                guard peek() == "}" else {
                    detailsState = .none
                    appendDiagnostic(
                        kind: .missingBlockClosingBrace,
                        message: "expected '}' to close free-text block",
                        startLine: startLine,
                        startColumn: startColumn
                    )
                    return emitEOF()
                }

                advance()
                detailsState = .none
                return emitToken(
                    .rBrace,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case .awaitingContent:
                break

            case .none:
                break
            }

            if let lit = scanDateLiteral() {
                return emitToken(
                    .dateLiteral(lit),
                    startLine: startLine,
                    startColumn: startColumn
                )
            }

            guard let c = peek() else {
                return emitEOF()
            }

            if c == "\"" {
                advance()

                let result = readQuotedLiteralResult()

                if !result.terminated {
                    appendDiagnostic(
                        kind: .unterminatedQuotedString,
                        message: "unterminated quoted string",
                        startLine: startLine,
                        startColumn: startColumn,
                        endLine: lastConsumedLine,
                        endColumn: max(lastConsumedColumn, startColumn),
                        lexeme: result.text
                    )
                }

                return emitToken(
                    .string(result.text),
                    startLine: startLine,
                    startColumn: startColumn
                )
            }

            switch c {
            case "{":
                advance()
                return emitToken(
                    .lBrace,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case "}":
                advance()
                return emitToken(
                    .rBrace,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case "(":
                advance()

                switch referenceState {
                case .awaitingEntityOpen:
                    referenceState = .entity

                case .awaitingAccountOpen:
                    referenceState = .account

                case .none, .entity, .account:
                    break
                }

                return emitToken(
                    .lPar,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case ")":
                advance()

                switch referenceState {
                case .entity, .account:
                    referenceState = .none

                case .none, .awaitingEntityOpen, .awaitingAccountOpen:
                    break
                }

                return emitToken(
                    .rPar,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case "-":
                if peek(aheadBy: 1) == ">" {
                    advance()
                    advance()

                    return emitToken(
                        .arrow,
                        startLine: startLine,
                        startColumn: startColumn
                    )
                }

            case ".":
                advance()
                return emitToken(
                    .dot,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case "=":
                advance()
                return emitToken(
                    .equals,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case ",":
                advance()
                return emitToken(
                    .comma,
                    startLine: startLine,
                    startColumn: startColumn
                )

            case "#":
                advance()
                return emitToken(
                    .hash,
                    startLine: startLine,
                    startColumn: startColumn
                )

            default:
                break
            }

            if CharacterSet.decimalDigits.contains(c) {
                switch referenceState {
                case .account:
                    let raw = readDigitsRaw()
                    return emitToken(
                        .account(raw),
                        startLine: startLine,
                        startColumn: startColumn
                    )

                case .none, .awaitingEntityOpen, .awaitingAccountOpen, .entity:
                    let number = readNumber()
                    return emitToken(
                        .number(number),
                        startLine: startLine,
                        startColumn: startColumn
                    )
                }
            }

            if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
                let ident = readIdent()

                if stringKeywordSet.contains(ident) {
                    detailsState = .awaitingOpen
                    return emitToken(
                        .keyword(ident),
                        startLine: startLine,
                        startColumn: startColumn
                    )
                } else if lexingSets.keywords.contains(ident) {
                    if ident == "for" {
                        referenceState = .awaitingEntityOpen
                    } else if ident == "in" {
                        referenceState = .awaitingAccountOpen
                    }

                    return emitToken(
                        .keyword(ident),
                        startLine: startLine,
                        startColumn: startColumn
                    )
                } else {
                    switch referenceState {
                    case .entity:
                        return emitToken(
                            .entity(ident),
                            startLine: startLine,
                            startColumn: startColumn
                        )

                    case .account:
                        return emitToken(
                            .account(ident),
                            startLine: startLine,
                            startColumn: startColumn
                        )

                    case .none, .awaitingEntityOpen, .awaitingAccountOpen:
                        return emitToken(
                            .ident(ident),
                            startLine: startLine,
                            startColumn: startColumn
                        )
                    }
                }
            }

            appendDiagnostic(
                kind: .invalidCharacter,
                message: "invalid character '\(Character(c))'",
                startLine: startLine,
                startColumn: startColumn,
                lexeme: String(Character(c))
            )

            advance()
        }
    }
}

// public struct EntryCompilerLexer: EntryCompilerLexing, Sendable {
//     public let scalars: [UnicodeScalar]
//     public var index: Int = 0

//     public var detailsState: EntryCompilerDetailsState = .none
//     public var referenceState: EntryCompilerReferenceState = .none

//     public var line: Int = 1
//     public var column: Int = 1

//     public let lexingSets: EntryCompilerLexingSets

//     private let stringKeywordSet: Set<String>

//     // public init(
//     //     source: String,
//     //     flavor: EntryCompilerLexingFlavor
//     // ) {
//     //     self.scalars = Array(source.unicodeScalars)
//     //     // self.lexingSets = aggregateLexingSets(flavor: flavor)
//     //     self.lexingSets = EntryCompilerLexingSetsCache.pointer(for: flavor)

//     //     // self.stringKeywordSet = aggregateLexingSets(flavor: .string).keywords
//     //     self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

//     // }

//     public init(
//         source: String,
//         flavor: EntryCompilerLexingFlavor
//     ) {
//         self.scalars = Array(source.unicodeScalars)
//         self.lexingSets = EntryCompilerLexingSetsCache.pointer(for: flavor)

//         switch flavor {
//         case .entries, .transactions:
//             self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

//         case .settings, .accounts, .entities, .string, .fallback:
//             self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

//         case .documents:
//             self.stringKeywordSet = []
//         }
//     }

//     public mutating func nextToken() -> EntryCompilerToken {
//         if detailsState == .awaitingContent {
//             let text = readUntilClosingBraceVerbatim()
//             detailsState = .awaitingClose
//             return .string(text)
//         }

//         skipWhitespaceAndComments()

//         switch detailsState {
//         case .awaitingOpen:
//             guard peek() == "{" else { return .eof }
//             advance()
//             detailsState = .awaitingContent
//             return .lBrace

//         case .awaitingContent:
//             let text = readUntilClosingBrace()
//             detailsState = .awaitingClose
//             return .string(text)

//         case .awaitingClose:
//             guard peek() == "}" else { return .eof }
//             advance()
//             detailsState = .none
//             return .rBrace

//         case .none:
//             break
//         }

//         if let lit = scanDateLiteral() { 
//             return .dateLiteral(lit) 
//         }

//         guard let c = peek() else { 
//             return .eof 
//         }

//         if c == "\"" {
//             advance()
//             return .string(readQuotedLiteral())
//         }

//         // 2) punctuation
//         switch c {
//         case "{": 
//             advance();
//             return .lBrace
//         case "}": 
//             advance();
//             return .rBrace

//         case "(":
//             advance()

//             switch referenceState {
//             case .awaitingEntityOpen:
//                 referenceState = .entity

//             case .awaitingAccountOpen:
//                 referenceState = .account

//             case .none, .entity, .account:
//                 break
//             }

//             return .lPar

//         case ")":
//             advance()

//             switch referenceState {
//             case .entity, .account:
//                 referenceState = .none

//             case .none, .awaitingEntityOpen, .awaitingAccountOpen:
//                 break
//             }

//             return .rPar

//         // case "(": 
//         //     advance(); 
//         //     return .lPar
//         // case ")": 
//         //     advance(); 
//         //     return .rPar

//         case "-":
//             if peek(aheadBy: 1) == ">" {
//                 advance()
//                 advance()
//                 return .arrow
//             }
//         case ".": 
//             advance();
//             return .dot
//         case "=": 
//             advance();
//             return .equals
//         case ",": 
//             advance();
//             return .comma
//         case "#": 
//             advance();
//             return .hash
//         default: 
//             break
//         }

//         // // 3) number
//         // if CharacterSet.decimalDigits.contains(c) {
//         //     return .number(readNumber())
//         // }

//         if CharacterSet.decimalDigits.contains(c) {
//             switch referenceState {
//             case .account:
//                 return .account(readDigitsRaw())

//             case .none, .awaitingEntityOpen, .awaitingAccountOpen, .entity:
//                 return .number(readNumber())
//             }
//         }

//         // 4) identifiers & keywords
//         if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
//             let ident = readIdent()

//             // if stringKeywordSet.contains(ident) {
//             //     detailsState = .awaitingOpen
//             //     return .keyword(ident)
//             // } else if lexingSets.keywords.contains(ident) {
//             //     return .keyword(ident)
//             // } else {
//             //     return .ident(ident)
//             // }

//             if stringKeywordSet.contains(ident) {
//                 detailsState = .awaitingOpen
//                 return .keyword(ident)
//             } else if lexingSets.keywords.contains(ident) {
//                 if ident == "for" {
//                     referenceState = .awaitingEntityOpen
//                 } else if ident == "in" {
//                     referenceState = .awaitingAccountOpen
//                 }

//                 return .keyword(ident)
//             } else {
//                 switch referenceState {
//                 case .entity:
//                     return .entity(ident)

//                 case .account:
//                     return .account(ident)

//                 case .none,
//                     .awaitingEntityOpen,
//                     .awaitingAccountOpen:
//                     return .ident(ident)
//                 }
//             }
//         }

//         advance()
//         return nextToken()
//     }
// }
