import AccountingSyntax
import Foundation
import Syntax
import Testing

private enum AccountingSyntaxFixtureError: Error {
    case missing_capture(String)
}

enum AccountingSyntaxTestSuite {
    static let suite = TestSuite("accounting-syntax", title: "Exact EC lexical syntax") {
        Test("EC vocabulary preserves language-specific kinds") {
            let language = try EntryCompilerSyntax.language()
            let vocabulary = try language.vocabulary()
            try Expect.equal(vocabulary.id, "ec", "language identity")
            try Expect.equal(vocabulary.definitions.count, 9, "all EC kinds declared")
            try Expect.equal(
                vocabulary.definition(named: "account")?.roles,
                [.identifier, .reference],
                "account role classification"
            )
        }

        Test("Unicode token offsets exclude trivia and quoted slashes") {
            let source = "  café \"//inside\" // outside\r\n42"
            let document = try EntryCompilerSyntax.document(source: source, flavor: .fallback)
            guard let identifier = document.captures.first(where: { $0.kind.name == "identifier" }),
                  let quoted = document.captures.first(where: { $0.kind.name == "string" }),
                  let comment = document.captures.first(where: { $0.kind.name == "comment" }) else {
                throw AccountingSyntaxFixtureError.missing_capture("identifier, string, comment")
            }
            try Expect.equal(identifier.segments[0].start.offset, 2, "leading trivia excluded")
            try Expect.equal(identifier.segments[0].end.offset, 7, "UTF-8, not scalar, end")
            try Expect.equal(String(document.text(in: identifier.segments[0]) ?? ""), "café", "exact unicode text")
            try Expect.equal(String(document.text(in: quoted.segments[0]) ?? ""), "\"//inside\"", "slash inside quotes remains a string")
            try Expect.equal(String(document.text(in: comment.segments[0]) ?? ""), "// outside", "only skipped comment classified")
            try Expect.equal(document.captures.filter { $0.kind.name == "comment" }.count, 1, "one actual comment")
            try Expect.equal(document.roles(for: identifier), [.identifier], "vocabulary default role")
        }

        Test("multiline details blocks do not create false comments") {
            let source = "details {line 1\n// inside block\nline 3}\n// trailing"
            let document = try EntryCompilerSyntax.document(source: source, flavor: .entries)
            guard let content = document.captures.first(where: { $0.kind.name == "string" }),
                  let comment = document.captures.first(where: { $0.kind.name == "comment" }) else {
                throw AccountingSyntaxFixtureError.missing_capture("details content and trailing comment")
            }
            try Expect.equal(
                String(document.text(in: content.segments[0]) ?? ""),
                "line 1\n// inside block\nline 3",
                "verbatim details content"
            )
            try Expect.equal(
                String(document.text(in: comment.segments[0]) ?? ""),
                "// trailing",
                "comment after last token captured at EOF"
            )
            try Expect.equal(document.captures.filter { $0.kind.name == "comment" }.count, 1, "no comment inside details")
        }
    }
}
