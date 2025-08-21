import Foundation

public extension EntryCompilerParsing {
    func parseEntityPath() throws -> EntityPath {
        guard case .ident("entity") = current else {
            throw ParserError.unexpectedToken(current, expected: "entity", at: loc())
        }
        advance()
        try expect(.lPar)
        let (domain, alias) = try readSegmentsUntilRPar()
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    func parseAccountPath() throws -> AccountPath {
        guard case .ident("account") = current else {
            throw ParserError.unexpectedToken(current, expected: "account", at: loc())
        }
        advance()
        try expect(.lPar)
        let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
        return AccountPath(segments: segs)
    }

    func parseEntityGroup(flexible: Bool) throws -> EntityPath {
        if flexible {
            if case .ident("entity") = current { return try parseEntityPath() }   // legacy
            if case .ident = current {                                           // bare dotted/arrow
                let segs = readFlatSegments()
                guard segs.count >= 2 else { throw ParserError.unexpectedToken(current, expected: "domain.alias.path", at: loc()) }
                return EntityPath(domain: segs[0], aliasSegments: Array(segs.dropFirst()))
            }
        }
        try expect(.lPar)
        let (domain, alias) = try readSegmentsUntilRPar()
        return EntityPath(domain: domain, aliasSegments: alias)
    }

    func parseAccountGroup(flexible: Bool) throws -> AccountPath {
        if flexible {
            if case .ident("account") = current { return try parseAccountPath() } // legacy
            if case .ident = current {                                            // bare dotted/arrow
                let segs = readFlatSegments()
                guard !segs.isEmpty else { throw ParserError.unexpectedToken(current, expected: "account path", at: loc()) }
                return AccountPath(segments: segs)
            }
        }
        switch current {
        case let .number(n): advance(); return AccountPath(segments: ["\(n)"])
        case .lPar:
            try expect(.lPar)
            let (_, segs) = try readSegmentsUntilRPar(allowAllAsAlias: true)
            return AccountPath(segments: segs)
        default:
            throw ParserError.unexpectedToken(current, expected: "number, dotted path, or (…)", at: loc())
        }
    }
}
