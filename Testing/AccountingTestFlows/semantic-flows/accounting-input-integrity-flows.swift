import Accounting
import AccountingCompiler
import AccountingParsers
import Foundation
import IO
import Primitives
import Readers
import TestFlows

extension AccountingTestFlowsSuite {
    static var accountingInputIntegrityFlow: TestFlow {
        TestFlow("accounting-input-integrity", tags: ["accounting", "lexing", "numeric"]) {
            Step("malformed numeric lexemes never produce zero-valued numbers") {
                for raw in ["1.2.3", "12..4", "123.", String(repeating: "9", count: 39)] {
                    var lexer = EntryCompilerLexer(source: raw, flavor: .entries)
                    let result = lexer.collectLexResult()
                    try Expect.equal(result.hasErrors, true, "reject numeric lexeme: \(raw)")
                    try Expect.equal(result.diagnostics.first?.kind, .invalidNumberLiteral, "typed numeric diagnostic")
                    try Expect.equal(result.tokens.contains(.number(0)), false, "no substituted zero")
                }
                var lexer = EntryCompilerLexer(source: "123.45", flavor: .entries)
                let result = lexer.collectLexResult()
                try Expect.equal(result.hasErrors, false, "valid numeric literal")
                try Expect.equal(result.tokens.first, .number(Decimal(string: "123.45")!), "exact numeric value")
            }
            Step("unicode numeric rejection advances to EOF") {
                var lexer = EntryCompilerLexer(source: "١٢٣", flavor: .entries)
                let result = lexer.collectLexResult()
                try Expect.equal(result.hasErrors, true, "non-ASCII decimal digits are rejected")
                try Expect.equal(result.tokens.last, .eof, "lexer made forward progress")
                try Expect.equal(result.diagnostics.first?.kind, .invalidNumberLiteral, "typed invalid literal")
            }
            Step("exact integer conversion rejects fractional and oversized values") {
                let parser = EntryCompilerEntriesParser(tokens: [.number(42), .eof], defaultTimeZone: TimeZone(secondsFromGMT: 0)!)
                try Expect.equal(try parser.expectInteger(), 42, "whole number")
                for number in [Decimal(string: "1.5")!, Decimal(string: "9223372036854775808")!] {
                    let bad = EntryCompilerEntriesParser(tokens: [.number(number), .eof], defaultTimeZone: TimeZone(secondsFromGMT: 0)!)
                    try Expect.throwsError("fractional or oversized Int rejected") {
                        _ = try bad.expectInteger()
                    }
                }
            }
            Step("entry dates are mandatory and never taken from the system clock") {
                let timezone = TimeZone(secondsFromGMT: 0)!
                let missing = EntryCompilerEntriesParser(
                    tokens: [.keyword("entry"), .lBrace, .rBrace, .eof],
                    defaultTimeZone: timezone
                )
                try Expect.throwsError("entry without date must fail") {
                    _ = try missing.parseEntries()
                }
                let provided = EntryCompilerEntriesParser(
                    tokens: [.keyword("entry"), .lBrace,
                             .keyword("date"), .equals, .dateLiteral("2024-02-29"),
                             .rBrace, .eof],
                    defaultTimeZone: timezone
                )
                let entries = try provided.parseEntries()
                try Expect.equal(entries.count, 1, "dated entry parses")
                let duplicate = EntryCompilerEntriesParser(
                    tokens: [.keyword("entry"), .lBrace,
                             .keyword("date"), .equals, .dateLiteral("2024-02-29"),
                             .keyword("date"), .equals, .dateLiteral("2024-03-01"),
                             .rBrace, .eof],
                    defaultTimeZone: timezone
                )
                try Expect.throwsError("duplicate entry dates must fail") {
                    _ = try duplicate.parseEntries()
                }
            }
            Step("entry loaders preserve canonical file order across concurrency") {
                try await verifyEntryLoaderOrder()
            }
            Step("EC source reader rejects invalid UTF-8 without fallback decoding") {
                try verifyECSourceDecoding()
            }
            Step("date blocks reject calendar normalization") {
                let tz = TimeZone(secondsFromGMT: 0)!
                let tokens: [EntryCompilerToken] = [
                    .lBrace,
                    .keyword("year"), .equals, .number(2025),
                    .keyword("month"), .equals, .number(2),
                    .keyword("day"), .equals, .number(31),
                    .rBrace, .eof
                ]
                let bad = EntryCompilerEntriesParser(tokens: tokens, defaultTimeZone: tz)
                try Expect.throwsError("February 31 rejected") { _ = try bad.parseDateBlock(tz: tz) }
                let valid = EntryCompilerEntriesParser(
                    tokens: [.lBrace, .keyword("year"), .equals, .number(2024),
                             .keyword("month"), .equals, .number(2),
                             .keyword("day"), .equals, .number(29), .rBrace, .eof],
                    defaultTimeZone: tz
                )
                _ = try valid.parseDateBlock(tz: tz)
                try Expect.throwsError("impossible date literal rejected") {
                    _ = try valid.parseDateLiteral("2025-02-31", in: tz)
                }
                _ = try valid.parseDateLiteral("2024-02-29", in: tz)
            }
            Step("shared date finalization retains both literal orders and year boundaries") {
                let tz = TimeZone(secondsFromGMT: 0)!
                let parser = EntryCompilerEntriesParser(tokens: [.eof], defaultTimeZone: tz)
                let iso = try parser.parseDateLiteral("2024-02-29", in: tz)
                let localOrder = try parser.parseDateLiteral("29-02-2024", in: tz)
                try Expect.equal(iso, localOrder, "ISO and day-first forms resolve identically")
                for invalid in ["2025-02-29", "2024-04-31", "2024-13-01", "2024-00-10"] {
                    try Expect.throwsError("invalid date literal: \(invalid)") {
                        _ = try parser.parseDateLiteral(invalid, in: tz)
                    }
                }
            }
            Step("shared date reader maintains block and literal forms") {
                let tz = TimeZone(secondsFromGMT: 0)!
                let block = EntryCompilerEntriesParser(
                    tokens: [.lBrace, .keyword("year"), .equals, .number(2024),
                             .keyword("month"), .equals, .number(2),
                             .keyword("day"), .equals, .number(29), .rBrace, .eof],
                    defaultTimeZone: tz
                )
                let blockDate = try block.parseAbsoluteDateValue(tz: tz)
                let literal = EntryCompilerEntriesParser(tokens: [.dateLiteral("2024-02-29"), .eof], defaultTimeZone: tz)
                try Expect.equal(try literal.parseAbsoluteDateValue(tz: tz), blockDate, "shared date reader")

                let incomplete = EntryCompilerEntriesParser(
                    tokens: [.lBrace, .keyword("year"), .equals, .number(2024),
                             .keyword("month"), .equals, .number(2), .rBrace, .eof],
                    defaultTimeZone: tz
                )
                try Expect.throwsError("incomplete date block") {
                    _ = try incomplete.parseAbsoluteDateValue(tz: tz)
                }
            }

            Step("path-inferred date completes through Primitives") {
                try verifyDateCompletion()
            }
        }
    }

    private static func verifyEntryLoaderOrder() async throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(
            "accounting-loader-order-\(UUID().uuidString)", isDirectory: true
        )
        let directory = root.appendingPathComponent("entries", isDirectory: true)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        // Write in reverse lexical order; the loader must not depend on creation order.
        for (name, id) in [("z.ec", 92), ("a.ec", 91)] {
            let url = directory.appendingPathComponent(name)
            try "entry { id = \(id) date = 2024-02-29 }".write(
                to: url, atomically: true, encoding: .utf8
            )
        }
        let project = EntryCompilerProject(root: root)
        let settings = try ECModelFixtures.parseSettings()
        let sequential = try loadEntriesSynchronously(from: project, settings: settings)
        let concurrent = try await EntryCompilerEntriesLoader.load(
            from: project, settings: settings, trace: false, placeholderWarnings: .silent
        )
        try Expect.equal(sequential.compactMap(\.id), [91, 92], "sync lexical order")
        try Expect.equal(concurrent.compactMap(\.id), [91, 92], "async lexical order")
    }

    private static func loadEntriesSynchronously(
        from project: EntryCompilerProject,
        settings: EntryCompilerSettings
    ) throws -> [Entry] {
        try EntryCompilerEntriesLoader.load(
            from: project, settings: settings, trace: false, placeholderWarnings: .silent
        )
    }

    private static func verifyECSourceDecoding() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent(
            "accounting-source-decoding-\(UUID().uuidString)", isDirectory: true
        )
        let directory = root.appendingPathComponent("entries", isDirectory: true)
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: root) }

        let file = directory.appendingPathComponent("invalid.ec")
        try Data([0xC3, 0x28]).write(to: file)
        let project = EntryCompilerProject(root: root)
        let settings = try ECModelFixtures.parseSettings()
        do {
            _ = try loadEntriesSynchronously(from: project, settings: settings)
            try Expect.true(false, "invalid UTF-8 must fail before lexing")
        } catch let error as TextReadError {
            switch error {
            case .undecodable(let url, let attempted):
                try Expect.equal(
                    FileSystem.default.resolve(url),
                    FileSystem.default.resolve(file),
                    "decode error identifies the same filesystem-resolved source file"
                )
                try Expect.equal(attempted.count, 1, "decode policy uses only one encoding")
            default:
                try Expect.true(false, "expected an undecodable-text error")
            }
        }
    }

    private static func verifyDateCompletion() throws {
        let timezone = TimeZone(secondsFromGMT: 0)!
        let leap = try DateCompletionContext(year: 2024, month: 2, timezone: timezone)
        let spec = try JSONDecoder().decode(
            Accounting.DateSpecification.self, from: Data(#"{"infer":29}"#.utf8)
        )
        let encoded = try JSONEncoder().encode(spec)
        try Expect.equal(
            String(decoding: encoded, as: UTF8.self),
            #"{"infer":29}"#,
            "Accounting preserves its established flat date JSON"
        )
        try Expect.equal(
            try JSONDecoder().decode(Primitives.DateSpecification.self, from: encoded),
            spec,
            "Accounting and Primitives share one date type and codec"
        )
        switch try spec.resolved(using: leap) {
        case .absolute(let date):
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timezone
            let parts = calendar.dateComponents([.year, .month, .day], from: date)
            try Expect.equal(parts.year, 2024, "inferred leap year")
            try Expect.equal(parts.month, 2, "inferred month")
            try Expect.equal(parts.day, 29, "inferred day")
        case .infer:
            try Expect.true(false, "resolution must eliminate inference")
        }
        let (year, quarter, month) = try inferYearQuarterMonth(
            from: "/ledger/entries/2024/1/2/main.ec"
        )
        try Expect.equal(year, 2024, "path year")
        try Expect.equal(quarter, 1, "path quarter")
        try Expect.equal(month, 2, "path month")
        try Expect.throwsError("path quarter must agree with month") {
            _ = try inferYearQuarterMonth(from: "/ledger/entries/2024/1/5/main.ec")
        }
        let period = try EntrySourcePeriod(
            pathComponents: ["ledger", "entries", "2024", "1", "2", "main.ec"]
        )
        try Expect.equal(period.year, 2024, "typed source year")
        try Expect.equal(period.quarter, 1, "typed source quarter")
        try Expect.equal(period.month, 2, "typed source month")
        try Expect.equal(
            try spec.resolved(using: period, timezone: timezone),
            try spec.resolved(using: leap),
            "source period delegates completion to Primitives"
        )
        try Expect.throwsError("typed source period validates quarter and month") {
            _ = try EntrySourcePeriod(year: 2024, quarter: 1, month: 5)
        }
        try Expect.throwsError("typed path rejects invalid year") {
            _ = try EntrySourcePeriod(pathComponents: ["entries", "nope", "1", "2", "main.ec"])
        }
        let nonLeap = try DateCompletionContext(year: 2025, month: 2, timezone: timezone)
        try Expect.throwsError("inferred leap day invalid for 2025") {
            _ = try spec.resolved(using: nonLeap)
        }
        let day31 = try JSONDecoder().decode(
            Accounting.DateSpecification.self, from: Data(#"{"infer":31}"#.utf8)
        )
        try Expect.throwsError("February 31 cannot roll into March") {
            _ = try day31.resolved(using: leap)
        }
    }
}
