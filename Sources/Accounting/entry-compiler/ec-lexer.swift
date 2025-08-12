import Foundation

public enum EntryCompilerToken: Equatable, Sendable {
    case keyword(String)          // entry, for, debit, credit, rm, date, details …
    case ident(String)            // entity, account, people, levi_ouwendijk …
    case number(Decimal)          // 200.00
    // punctuation
    case lBrace                   // {
    case rBrace                   // }
    case lPar                     // (
    case rPar                     // )
    case arrow                    // ->
    case dot                      // .
    case equals                   // =

    case string(String)           // details { … }

    case dateLiteral(String)   // e.g. "2025-02-03" or "03/02/2025"

    case eof
}

public struct EntryCompilerLexer: Sendable {
    private let scalars: [UnicodeScalar]
    private var index: Int = 0

    private enum DetailsState { case none, awaitingOpen, awaitingContent, awaitingClose }
    private var detailsState: DetailsState = .none

    public init(source: String) {
        self.scalars = Array(source.unicodeScalars)
    }

    public mutating func nextToken() -> EntryCompilerToken {
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
        default: break
        }

        // 3) number
        if CharacterSet.decimalDigits.contains(c) {
            return .number(readNumber())
        }

        // 4) identifiers & keywords
        if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
            let ident = readIdent()
            let kwSet: Set<String> = [
                "entry", 

                "details",

                "date", "infer",
                "year","month","day",

                "for", "in",

                "to","from",

                "debit", "credit", 
                "dr", "cr",

                "posting",
                "line",

                "inventory",
                "adding", "removing",
                "addition", "reduction",
                "add", "rm", "remove"
            ]
            if ident == "details" {
                detailsState = .awaitingOpen
                return .keyword("details")
            } else if kwSet.contains(ident) {
                return .keyword(ident)
            } else {
                return .ident(ident)
            }
        }

        advance()
        return nextToken()
    }

    private mutating func skipWhitespaceAndComments() {
        while let c = peek() {
            if CharacterSet.whitespacesAndNewlines.contains(c) {
                advance(); continue
            }
            // single‑line comment `// ...`
            if c == "/" && peek(aheadBy: 1) == "/" {
                advance(); advance() // consume '//'
                while let c2 = peek(), c2 != "\n" { advance() }
                continue
            }
            break
        }
    }

    private mutating func readNumber() -> Decimal {
        var buffer = ""
        while let c = peek(), CharacterSet(charactersIn: "0123456789.").contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return Decimal(string: buffer) ?? 0
    }

    private mutating func readIdent() -> String {
        var buffer = ""
        while let c = peek(), CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")) .contains(c) {
            buffer.append(Character(c))
            advance()
        }
        return buffer
    }

    private mutating func readPattern(_ pattern: String) throws -> String {
        let regex = try NSRegularExpression(pattern: "^\(pattern)")
        let remaining = String(scalars[index...].map { Character($0) })
        let nsrange = NSRange(location: 0, length: remaining.utf16.count)
        if let m = regex.firstMatch(in: remaining, options: [], range: nsrange),
           let range = Range(m.range, in: remaining) {
            let lit = String(remaining[range])
            index += lit.utf16.count  // consume matched chars
            return lit
        }
        throw NSError(domain: "NoPattern", code: 1)
    }

    private mutating func readUntilClosingBrace() -> String {
        var depth = 1
        var buffer = ""
        while let c = peek() {
            if c == "{" {
                advance()
                depth += 1
                buffer.append("{")
                continue
            }
            if c == "}" {
                depth -= 1
                if depth == 0 {
                    break
                }
                advance()
                buffer.append("}")
                continue
            }
            advance()
            buffer.append(Character(c))
        }
        return buffer.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @inline(__always) private func peek(aheadBy n: Int = 0) -> UnicodeScalar? {
        let i = index + n
        return i < scalars.count ? scalars[i] : nil
    }
    @inline(__always) private mutating func advance() { 
        index += 1 
    }

    public mutating func collectAllTokens() -> [EntryCompilerToken] {
        var tokens: [EntryCompilerToken] = []
        while true {
            let t = self.nextToken()
            tokens.append(t)
            if t == .eof { break }
        }
        return tokens
    }
}
