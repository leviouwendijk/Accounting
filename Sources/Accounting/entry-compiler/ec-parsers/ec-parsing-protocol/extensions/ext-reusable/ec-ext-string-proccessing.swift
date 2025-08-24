import Foundation

public enum EntryCompilerFreeTextMode {
    case strict(expected: String)   // throw on unexpected token
    case lenient                    // stop + return on unexpected
}

public extension EntryCompilerParsing {
    @inline(__always) func appendWord(_ out: inout String, _ s: String) {
        if !out.isEmpty { out.append(" ") }
        out.append(s)
    }

    @inline(__always) func appendDot(_ out: inout String) {
        out.append(".")
    }

    @inline(__always) func nextIsKeyStart() -> Bool {
        let i = core.index
        let toks = core.tokens
        guard i < toks.count - 1 else { return false }
        switch toks[i] {
        case .ident, .keyword:
            return toks[i + 1] == .equals
        default:
            return false
        }
    }

    @inline(__always) func nextIsOneOfKeysStart(_ keys: Set<String>) -> Bool {
        let i = core.index
        let toks = core.tokens
        guard i < toks.count - 1 else { return false }
        switch toks[i] {
        case let .ident(k), let .keyword(k):
            return keys.contains(k) && toks[i + 1] == .equals
        default:
            return false
        }
    }

    @inlinable
    func collectFreeText(until stop: () -> Bool, mode: EntryCompilerFreeTextMode) throws -> String {
        var out = ""
        while !stop() {
            switch current {
            case let .string(s):  appendWord(&out, s); advance()
            case let .ident(s):   appendWord(&out, s); advance()
            case let .keyword(s): appendWord(&out, s); advance()
            case let .number(n):  appendWord(&out, "\(n)"); advance()
            case let .dateLiteral(s): appendWord(&out, s); advance()
            case .dot:            appendDot(&out); advance()
            case .hash:           out.append("#"); advance() 
            default:
                switch mode {
                case .lenient: return out
                case .strict(let expected):
                    throw ParserError.unexpectedToken(current, expected: expected, at: loc())
                }
            }
        }
        return out
    }
}
