import Foundation

public struct EntryCompilerLexer: EntryCompilerLexing, Sendable {
    public let scalars: [UnicodeScalar]
    public var index: Int = 0

    public var detailsState: EntryCompilerDetailsState = .none
    public var referenceState: EntryCompilerReferenceState = .none

    public var line: Int = 1
    public var column: Int = 1

    public let lexingSets: EntryCompilerLexingSets

    private let stringKeywordSet: Set<String>

    // public init(
    //     source: String,
    //     flavor: EntryCompilerLexingFlavor
    // ) {
    //     self.scalars = Array(source.unicodeScalars)
    //     // self.lexingSets = aggregateLexingSets(flavor: flavor)
    //     self.lexingSets = EntryCompilerLexingSetsCache.pointer(for: flavor)

    //     // self.stringKeywordSet = aggregateLexingSets(flavor: .string).keywords
    //     self.stringKeywordSet = EntryCompilerLexingSetsCache.string.keywords

    // }

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

    public mutating func nextToken() -> EntryCompilerToken {
        if detailsState == .awaitingContent {
            let text = readUntilClosingBraceVerbatim()
            detailsState = .awaitingClose
            return .string(text)
        }

        skipWhitespaceAndComments()

        switch detailsState {
        case .awaitingOpen:
            guard peek() == "{" else { return .eof }
            advance()
            detailsState = .awaitingContent
            return .lBrace

        case .awaitingContent:
            let text = readUntilClosingBrace()
            detailsState = .awaitingClose
            return .string(text)

        case .awaitingClose:
            guard peek() == "}" else { return .eof }
            advance()
            detailsState = .none
            return .rBrace

        case .none:
            break
        }

        if let lit = scanDateLiteral() { 
            return .dateLiteral(lit) 
        }

        guard let c = peek() else { 
            return .eof 
        }

        if c == "\"" {
            advance()
            return .string(readQuotedLiteral())
        }

        // 2) punctuation
        switch c {
        case "{": 
            advance();
            return .lBrace
        case "}": 
            advance();
            return .rBrace
        case "(": 
            advance(); 
            return .lPar
        case ")": 
            advance(); 
            return .rPar
        case "-":
            if peek(aheadBy: 1) == ">" {
                advance()
                advance()
                return .arrow
            }
        case ".": 
            advance();
            return .dot
        case "=": 
            advance();
            return .equals
        case ",": 
            advance();
            return .comma
        case "#": 
            advance();
            return .hash
        default: 
            break
        }

        // 3) number
        if CharacterSet.decimalDigits.contains(c) {
            return .number(readNumber())
        }

        // 4) identifiers & keywords
        if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
            let ident = readIdent()

            if stringKeywordSet.contains(ident) {
                detailsState = .awaitingOpen
                return .keyword(ident)
            } else if lexingSets.keywords.contains(ident) {
                return .keyword(ident)
            } else {
                return .ident(ident)
            }
        }

        advance()
        return nextToken()
    }
}
