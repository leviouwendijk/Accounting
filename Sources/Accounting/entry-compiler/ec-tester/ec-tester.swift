import Foundation
import plate

public enum EntryCompilerTesterError: Error, Sendable {
    case mismatch
}

public struct EntryCompilerTester: Sendable {
    public let compiler: EntryCompiler
    public let ecString: String
    public let expected: [EntryCompilerToken]
    public let overrideTZ: TimeZone?

    // Build compiler from a project root
    public init(
        root: URL,
        ecString: String,
        expected: [EntryCompilerToken],
        overrideTZ: TimeZone? = nil
    ) throws {
        self.compiler = try EntryCompiler(root: root)
        self.ecString = ecString
        self.expected = expected
        self.overrideTZ = overrideTZ
    }

    // Or inject an existing compiler
    public init(
        compiler: EntryCompiler,
        ecString: String,
        expected: [EntryCompilerToken],
        overrideTZ: TimeZone? = nil
    ) {
        self.compiler = compiler
        self.ecString = ecString
        self.expected = expected
        self.overrideTZ = overrideTZ
    }

    public func actualTokens() -> [EntryCompilerToken] {
        compiler.lex(ecString)
    }

    public func test() throws {
        let actual = actualTokens()

        if actual == expected {
            print("Lexer test passed (\(actual.count) tokens)".ansi(.green, .bold))
        } else {
            print("Lexer test failed".ansi(.red, .bold))
            print("Expected (\(expected.count)):", expected)
            print("  Actual (\(actual.count)):", actual)
            throw EntryCompilerTesterError.mismatch
        }

        // Parse with default TZ from settings, unless overridden
        let tz = overrideTZ ?? compiler.settings.entry.defaultTimezone
        let parser = compiler.parsers.makeEntries(actual, tz)
        let entries = try parser.parseEntries()

        print("Parsed entries:")
        for e in entries { print(e.viewableString) }
    }
}

// testing helpers

public struct TokenDTO: Codable {
    public let type: String
    public let value: String?
}

public func tokensToDTO(_ toks: [EntryCompilerToken]) -> [TokenDTO] {
    toks.map {
        switch $0 {
        case .keyword(let s):   return .init(type: "keyword", value: s)
        case .ident(let s):     return .init(type: "ident",   value: s)
        case .number(let d):    return .init(type: "number",  value: "\(d)")
        case .lBrace:           return .init(type: "lBrace",  value: nil)
        case .rBrace:           return .init(type: "rBrace",  value: nil)
        case .lPar:             return .init(type: "lPar",    value: nil)
        case .rPar:             return .init(type: "rPar",    value: nil)
        case .arrow:            return .init(type: "arrow",   value: nil)
        case .dot:              return .init(type: "dot",     value: nil)
        case .equals:           return .init(type: "equals",  value: nil)
        case .string(let s):    return .init(type: "string",  value: s)
        case .dateLiteral(let s): return .init(type: "date",  value: s)
        case .comma:            return .init(type: "punc",    value: ",")
        case .hash:            return .init(type: "hash",    value: "#")
        case .eof:              return .init(type: "eof",     value: nil)
        }
    }
}

public func encodeTokensJSON(_ toks: [EntryCompilerToken]) throws -> Data {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try enc.encode(tokensToDTO(toks))
}

public func encodeASTJSON(_ entries: [Entry]) throws -> Data {
    let enc = JSONEncoder()
    enc.outputFormatting = [.prettyPrinted, .sortedKeys]
    enc.dateEncodingStrategy = .iso8601
    return try enc.encode(entries)
}

public func normalizeASTDates(_ data: Data, in tz: TimeZone) -> Data {
    func parse(_ d: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: d, options: [])
    }
    guard var root = parse(data) else { return data }

    let iso = ISO8601DateFormatter()
    var calLocal = Calendar(identifier: .gregorian); calLocal.timeZone = tz
    var calUTC   = Calendar(identifier: .gregorian); calUTC.timeZone   = TimeZone(secondsFromGMT: 0)!

    func norm(_ any: Any) -> Any {
        switch any {
        case let s as String:
            if let d = iso.date(from: s) {
                let comps = calLocal.dateComponents([.year, .month, .day], from: d)
                let normalized = calUTC.date(from: DateComponents(year: comps.year, month: comps.month, day: comps.day))!
                return iso.string(from: normalized)
            }
            return s
        case let a as [Any]:
            return a.map { norm($0) }
        case var o as [String: Any]:
            for (k, v) in o { o[k] = norm(v) }
            return o
        default:
            return any
        }
    }

    root = norm(root)
    return try! JSONSerialization.data(withJSONObject: root, options: [.sortedKeys, .prettyPrinted])
}
