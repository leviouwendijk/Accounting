import Foundation
import Accounting

public extension EntryCompilerParsing {
    // chart { find rgs  version { major = 3  minor = 8 } }
    func parseChartBlock() throws -> (find: String, version: ChartVersion) {
        try expectKeyword("chart"); try beginBlock()

        var findStr: String?
        var major: Int?
        var minor: Int?

        while current != .rBrace && current != .eof {
            switch current {

            case .keyword("find"):
                advance()
                findStr = try expectIdentValue()

            case .keyword("version"):
                let parsed = try parseChartVersionBlock()
                major = parsed.major
                minor = parsed.minor

            default:
                throw ParserError.unexpectedToken(
                    current,
                    expected: "find or version",
                    at: loc()
                )
            }
        }

        try endBlock()

        guard let f = findStr else {
            throw ParserError.unexpectedToken(current, expected: "find <keyword>", at: loc())
        }
        guard let ma = major, let mi = minor else {
            throw ParserError.unexpectedToken(current, expected: "version { major minor }", at: loc())
        }

        return (find: f, version: ChartVersion(major: ma, minor: mi))
    }

    // version { major = 3  minor = 8 }
    func parseChartVersionBlock() throws -> (major: Int, minor: Int) {
        try expectKeyword("version"); try beginBlock()

        var major: Int?
        var minor: Int?

        while current != .rBrace && current != .eof {
            switch current {
            case .keyword("major"):
                advance(); try expect(.equals)
                major = try expectInteger()
            case .keyword("minor"):
                advance(); try expect(.equals)
                minor = try expectInteger()
            default:
                throw ParserError.unexpectedToken(current, expected: "major or minor", at: loc())
            }
        }

        try endBlock()

        guard let ma = major, let mi = minor else {
            throw ParserError.unexpectedToken(current, expected: "major & minor", at: loc())
        }
        return (ma, mi)
    }
}
