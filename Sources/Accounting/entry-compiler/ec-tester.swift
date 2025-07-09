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

        var parser = EntryCompilerParser(tokens: actual)
        let entries = try parser.parseEntries()
        print("Parsed entries:")
        for e in entries {
            print(e.viewableString)
        }
    }
}
