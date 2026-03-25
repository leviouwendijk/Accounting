import Foundation

public extension EntryCompilerParsing {
    func parseAccountPath() throws -> AccountPath {
        switch current {
        case .ident("account"), .keyword("account"):
            break

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "account",
                at: loc()
            )
        }

        advance()
        try expect(.lPar)
        let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
        return AccountPath(segments: segs)
    }

    func parseAccountGroup(flexible: Bool) throws -> AccountPath {
        if flexible {
            switch current {
            case .ident("account"), .keyword("account"):
                return try parseAccountPath()

            case .ident, .account:
                let segs = readFlatSegments()
                guard !segs.isEmpty else {
                    throw ParserError.unexpectedToken(
                        current,
                        expected: "account path",
                        at: loc()
                    )
                }
                return AccountPath(segments: segs)

            default:
                break
            }
        }

        switch current {
        case let .number(n):
            advance()
            return AccountPath(segments: ["\(n)"])

        case let .account(raw):
            advance()
            return AccountPath(segments: [raw])

        case .lPar:
            try expect(.lPar)
            let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
            return AccountPath(segments: segs)

        default:
            throw ParserError.unexpectedToken(
                current,
                expected: "number, dotted path, or (…)",
                at: loc()
            )
        }
    }
}

// public extension EntryCompilerParsing {
//     func parseAccountPath() throws -> AccountPath {
//         guard case .ident("account") = current else {
//             throw ParserError.unexpectedToken(current, expected: "account", at: loc())
//         }
//         advance()
//         try expect(.lPar)
//         let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
//         return AccountPath(segments: segs)
//     }

//     func parseAccountGroup(flexible: Bool) throws -> AccountPath {
//         if flexible {
//             if case .ident("account") = current { return try parseAccountPath() } // legacy
//             if case .ident = current {                                            // bare dotted/arrow
//                 let segs = readFlatSegments()
//                 guard !segs.isEmpty else { throw ParserError.unexpectedToken(current, expected: "account path", at: loc()) }
//                 return AccountPath(segments: segs)
//             }
//         }
//         switch current {
//         case let .number(n): advance(); return AccountPath(segments: ["\(n)"])
//         case .lPar:
//             try expect(.lPar)
//             let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
//             return AccountPath(segments: segs)
//         default:
//             throw ParserError.unexpectedToken(current, expected: "number, dotted path, or (…)", at: loc())
//         }
//     }
// }
