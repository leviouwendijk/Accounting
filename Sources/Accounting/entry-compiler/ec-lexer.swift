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

    case eof
}

public struct EntryCompilerLexer: Sendable {
    private let scalars: [UnicodeScalar]
    private var index: Int = 0
    private var pendingDetailsBlock: Bool = false

    public init(source: String) {
        self.scalars = Array(source.unicodeScalars)
    }

    public mutating func nextToken() -> EntryCompilerToken {
        skipWhitespaceAndComments()

        if pendingDetailsBlock {
            pendingDetailsBlock = false
            advance()
            return .lBrace
        }
        
        guard let c = peek() else { return .eof }

        // punctuation
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

        if CharacterSet.decimalDigits.contains(c) {
            return .number(readNumber())
        }

        if CharacterSet.letters.union(CharacterSet(charactersIn: "_")).contains(c) {
            let ident = readIdent()

            if ident == "details" {
                pendingDetailsBlock = true
                return .keyword(ident)
            }

            let kwSet: Set<String> = ["entry","for","debit","credit","date","in","rm","to","from"]
            if kwSet.contains(ident) {
                return .keyword(ident)
            }
            return .ident(ident)
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

    private mutating func readUntilClosingBrace() -> String {
        var depth = 1
        var buffer = ""
        while let c = peek() {
            advance()
            if c == "{" { depth += 1; buffer.append("{"); continue }
            if c == "}" {
                depth -= 1
                if depth == 0 { break }
                buffer.append("}"); continue
            }
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
}

public struct EntityPath: Hashable, Codable, Sendable {
    public let domain: String            // "people"
    public let aliasSegments: [String]   // ["levi", "ouwendijk"]
    public init(domain: String, aliasSegments: [String]) {
        self.domain = domain
        self.aliasSegments = aliasSegments
    }

    public var alias: String { aliasSegments.joined(separator: "_") }
}

public struct AccountPath: Hashable, Codable, Sendable {
    public let segments: [String]
    public init(segments: [String]) { self.segments = segments }
}

public struct Line: Hashable, Codable, Sendable {
    public let entity: EntityPath
    public let account: AccountPath
    public let direction: Direction
    public let amount: Decimal
    public init(entity: EntityPath, account: AccountPath, direction: Direction, amount: Decimal) {
        self.entity = entity
        self.account = account
        self.direction = direction
        self.amount = amount
    }
}

public struct Entry: Hashable, Codable, Sendable {
    public var date: Date
    public var lines: [Line]
    public var details: String? = nil
    public init(date: Date = Date(), lines: [Line] = [], details: String? = nil) {
        self.date = date
        self.lines = lines
        self.details = details
    }
}

public protocol SQLDatabase: Sendable {
    func query<T>(_ sql: String, binds: [Encodable]) throws -> T
}

public struct Resolver: Sendable {
    public let db: SQLDatabase
    public init(db: SQLDatabase) { self.db = db }
    public func entityID(for path: EntityPath) throws -> Int {
        throw NSError(domain: "Resolver", code: 0, userInfo: [NSLocalizedDescriptionKey:"not implemented"])
    }
    public func accountID(for path: AccountPath) throws -> Int {
        throw NSError(domain: "Resolver", code: 0, userInfo: [NSLocalizedDescriptionKey:"not implemented"])
    }
}

public struct SourceLocation: CustomStringConvertible, Sendable {
    public let line: Int
    public let column: Int
    public var description: String { "\(line):\(column)" }
}
