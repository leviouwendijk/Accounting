import Foundation

public struct EntryCompilerLexer: EntryCompilerLexing, Sendable {
    public let scalars: [UnicodeScalar]
    public var index: Int = 0

    public var detailsState: EntryCompilerDetailsState = .none

    public var line: Int = 1
    public var column: Int = 1

    public init(source: String) {
        self.scalars = Array(source.unicodeScalars)
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

        if let lit = try? readPattern("\\d{4}[-/.]\\d{2}[-/.]\\d{2}") {
            return .dateLiteral(lit)
        }
        if let lit = try? readPattern("\\d{2}[-/.]\\d{2}[-/.]\\d{4}") {
            return .dateLiteral(lit)
        }

        guard let c = peek() else { return .eof }

        // 2) punctuation
        switch c {
        case "{": advance(); return .lBrace
        case "}": advance(); return .rBrace
        case "(": advance(); return .lPar
        case ")": advance(); return .rPar
        case "-":
            if peek(aheadBy: 1) == ">" {
                advance(); advance()
                return .arrow
            }
        case ".": advance(); return .dot
        case "=": advance(); return .equals
        case ",": advance(); return .comma
        case "#": advance(); return .hash
        default: break
        }

        // 3) number
        if CharacterSet.decimalDigits.contains(c) {
            return .number(readNumber())
        }

        // 4) identifiers & keywords
        if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
            let ident = readIdent()

            let kwSet = entryCompilerKeywordSet()
            let kwStringBlocks = entryCompilerStringBlockKeywordSet()

            if kwStringBlocks.contains(ident) {
                detailsState = .awaitingOpen
                return .keyword(ident)
            } else if kwSet.contains(ident) {
                return .keyword(ident)
            } else {
                return .ident(ident)
            }
        }

        advance()
        return nextToken()
    }
}
