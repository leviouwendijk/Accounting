import Foundation

public extension EntryCompilerParsing {
    /// Reads a single alias token that may start with a number and/or contain
    /// adjacent number/ident chunks without separators, e.g. "20x4mm".
    /// Accepts either:  <alias>  or  (<alias>)
    @inlinable
    func readSingleAliasFlexible() throws -> String {
        if current == .lPar {
            advance()

            var parts: [String] = []
            parts.reserveCapacity(4)
            var saw = false

            while current != .rPar && current != .eof {
                switch current {
                case let .ident(s), let .entity(s), let .account(s):
                    parts.append(s)
                    saw = true
                    advance()

                case let .number(n):
                    parts.append("\(n)")
                    saw = true
                    advance()

                default:
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "alias (letters/digits)",
                        at: loc()
                    )
                }
            }

            try expect(.rPar)

            guard saw else {
                throw ParserError.unexpectedToken(
                    current,
                    expected: "non-empty alias",
                    at: loc()
                )
            }

            return parts.joined()
        }

        var parts: [String] = []
        parts.reserveCapacity(4)
        var saw = false

        while true {
            switch current {
            case let .ident(s), let .entity(s), let .account(s):
                parts.append(s)
                saw = true
                advance()

            case let .number(n):
                parts.append("\(n)")
                saw = true
                advance()

            default:
                break
            }

            if !(current.isIdentOrNumber) {
                break
            }
        }

        guard saw else {
            throw ParserError.unexpectedToken(
                current,
                expected: "alias (letters/digits)",
                at: loc()
            )
        }

        if current == .dot || current == .arrow {
            throw ParserError.unexpectedToken(
                current,
                expected: "end of alias (no path separators)",
                at: loc()
            )
        }

        return parts.joined()
    }
}

public extension EntryCompilerToken {
    var isIdentOrNumber: Bool {
        if case .ident = self { return true }
        if case .number = self { return true }
        if case .entity = self { return true }
        if case .account = self { return true }
        return false
    }
}

// public extension EntryCompilerParsing {
//     @inlinable
//     func readSingleAliasFlexible() throws -> String {
//         if current == .lPar {
//             advance()
//             var parts: [String] = []
//             parts.reserveCapacity(4)
//             var saw = false
//             while current != .rPar && current != .eof {
//                 switch current {
//                 case let .ident(s): parts.append(s); saw = true; advance()
//                 case let .number(n): parts.append("\(n)"); saw = true; advance()
//                 default:
//                     throw ParserError.unexpectedToken(current, expected: "alias (letters/digits)", at: loc())
//                 }
//             }
//             try expect(.rPar)
//             guard saw else { throw ParserError.unexpectedToken(current, expected: "non-empty alias", at: loc()) }
//             return parts.joined()
//         }

//         // Bare form: 20x4mm
//         var parts: [String] = []
//         parts.reserveCapacity(4)
//         var saw = false
//         while true {
//             switch current {
//             case let .ident(s): parts.append(s); saw = true; advance()
//             case let .number(n): parts.append("\(n)"); saw = true; advance()
//             default: break
//             }
//             if !(current.isIdentOrNumber) { break }
//         }

//         guard saw else {
//             throw ParserError.unexpectedToken(current, expected: "alias (letters/digits)", at: loc())
//         }
//         if current == .dot || current == .arrow {
//             throw ParserError.unexpectedToken(current, expected: "end of alias (no path separators)", at: loc())
//         }
//         return parts.joined()
//     }
// }

// public extension EntryCompilerToken {
//     var isIdentOrNumber: Bool {
//         if case .ident = self { return true }
//         if case .number = self { return true }
//         return false
//     }
// }
