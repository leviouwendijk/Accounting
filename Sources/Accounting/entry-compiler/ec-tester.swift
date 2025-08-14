import Foundation
import plate

public enum EntryCompilerTesterError: Error, Sendable {
    case mismatch
}

public struct EntryCompilerTester: Sendable {
    public let ecString: String
    public let expected: [EntryCompilerToken]
    
    public init(
        ecString: String,
        expected: [EntryCompilerToken]
    ) {
        self.ecString = ecString
        self.expected = expected
    }

    public func actual() -> [EntryCompilerToken] {
        var lexer = EntryCompilerLexer(source: ecString)
        var actual: [EntryCompilerToken] = []
        while true {
            let tok = lexer.nextToken()
            actual.append(tok)
            if tok == .eof { break }
        }
        return actual
    }

    public func test() throws {
        let actual = actual()

        if actual == expected {
            print("Lexer test passed (\(actual.count) tokens)".ansi(.green, .bold))
        } else {
            print("Lexer test failed".ansi(.red, .bold))
            print("Expected (\(expected.count)):", expected)
            print("  Actual (\(actual.count)):", actual)
            throw EntryCompilerTesterError.mismatch
        }

        let parser = EntryCompilerEntriesParser(tokens: actual)
        let entries = try parser.parseEntries()
        print("Parsed entries:")
        for e in entries {
            print(e.viewableString)
        }
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
