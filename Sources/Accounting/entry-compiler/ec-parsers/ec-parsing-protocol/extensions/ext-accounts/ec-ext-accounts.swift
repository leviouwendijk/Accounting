import Foundation

public extension EntryCompilerParsing {
    // Parse an account reference *flexibly* from entries:
    //   - number       → 10201
    //   - account 10201
    //   - account(10201)
    //   - dotted/arrow path (legacy) → kept as .path([...]) for the store to decide.
    @inlinable
    func parseAccountRefFlexible() throws -> AccountRef {
        // Single number
        if case let .number(n) = current {
            let code = String((n as NSDecimalNumber).intValue)
            advance()
            return .code(code)
        }

        // "account" prefix
        if case .ident("account") = current {
            advance()
            if current == .lPar {
                try expect(.lPar)
                guard case let .number(n) = current else {
                    throw ParserError.unexpectedToken(current, expected: "number (account code)", at: loc())
                }
                let code = String((n as NSDecimalNumber).intValue)
                advance(); try expect(.rPar)
                return .code(code)
            } else if case let .number(n) = current {
                let code = String((n as NSDecimalNumber).intValue)
                advance()
                return .code(code)
            }
        }

        // Fallback: dotted/arrow segments
        let segs = readFlatSegments()
        if let first = segs.first, Int(first) != nil {
            return .code(first)
        }
        return .path(segs)
    }

    // Convenience: parse list of account refs inside "( ... )" with commas optional.
    @inlinable
    func parseAccountRefListInParens() throws -> [AccountRef] {
        try expect(.lPar)
        var out: [AccountRef] = []
        while current != .rPar && current != .eof {
            out.append(try parseAccountRefFlexible())
            if current == .comma { advance(); continue }
            break
        }
        try expect(.rPar)
        return out
    }
}
