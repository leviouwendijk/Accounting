import Foundation

public extension EntryCompilerParsing {
    @inlinable
    func parseSelectBlock() throws -> EntrySelect {
        try expect(.keyword("select"))
        try beginBlock()

        var groups: [String] = []

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("group"), .ident("group"):
                try expectFieldEquals("group")
                groups.append(try expectNameNumberOrStringValue())

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "group|}",
                    at: loc()
                )
            }
        }

        try endBlock()

        return EntrySelect(
            groups: EntrySelect.normalizedUniqueGroups(groups)
        )
    }
}
