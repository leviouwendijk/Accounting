import Foundation

enum ECSourceBlockExtractor {
    static func extract(from source: String) -> [ECSourceBlock] {
        let lines = source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).map(String.init)

        guard !lines.isEmpty else {
            return []
        }

        var out: [ECSourceBlock] = []
        var i = 0
        var lastConsumedLineIndex = -1

        while i < lines.count {
            guard let kind = topLevelBlockKind(in: lines[i]) else {
                i += 1
                continue
            }

            let semanticStartIndex = i
            let semanticStartLine = semanticStartIndex + 1

            var renderStartIndex = semanticStartIndex
            var j = semanticStartIndex - 1

            while j > lastConsumedLineIndex {
                let line = lines[j]

                if isBlank(line) || isCommentOnly(line) {
                    renderStartIndex = j
                    j -= 1
                    continue
                }

                break
            }

            var depth = 0
            var sawOpeningBrace = false
            var endIndex = semanticStartIndex
            var k = semanticStartIndex

            while k < lines.count {
                let scan = stripLineComment(from: lines[k])

                for ch in scan {
                    if ch == "{" {
                        depth += 1
                        sawOpeningBrace = true
                    } else if ch == "}" {
                        depth -= 1
                    }
                }

                if sawOpeningBrace && depth <= 0 {
                    endIndex = k
                    break
                }

                k += 1
            }

            let clampedRenderStart = max(
                renderStartIndex,
                lastConsumedLineIndex + 1
            )

            let blockLines = Array(lines[clampedRenderStart...endIndex])
            let blockSource = blockLines.joined(separator: "\n")
            let summarySource = Array(lines[semanticStartIndex...min(endIndex, semanticStartIndex + 12)])
                .joined(separator: "\n")

            out.append(
                ECSourceBlock(
                    kind: kind,
                    source: blockSource,
                    renderStartLine: clampedRenderStart + 1,
                    semanticStartLine: semanticStartLine,
                    endLine: endIndex + 1,
                    summary: makeSummary(from: summarySource)
                )
            )

            lastConsumedLineIndex = endIndex
            i = endIndex + 1
        }

        return out
    }

    private static func topLevelBlockKind(in line: String) -> ECSourceBlockKind? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            return nil
        }

        guard !trimmed.hasPrefix("//") else {
            return nil
        }

        let head = stripLineComment(from: trimmed)

        guard let braceIndex = head.firstIndex(of: "{") else {
            return nil
        }

        let beforeBrace = head[..<braceIndex]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !beforeBrace.isEmpty else {
            return nil
        }

        let keyword = firstToken(in: beforeBrace)

        switch keyword {
        case "entry":
            return .entry
        case "entity":
            return .entity
        case "account":
            return .account
        case "transaction":
            return .transaction
        case "document":
            return .document
        case "assertion":
            return .assertion
        case "settings":
            return .settings
        default:
            return nil
        }
    }

    private static func firstToken(in text: String) -> String {
        var token = ""

        for ch in text {
            if ch == " " || ch == "\t" {
                break
            }

            token.append(ch)
        }

        return token
    }

    private static func isBlank(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func isCommentOnly(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
    }

    private static func stripLineComment(from line: String) -> String {
        guard let range = line.range(of: "//") else {
            return line
        }

        return String(line[..<range.lowerBound])
    }

    private static func makeSummary(from source: String) -> ECSourceBlockSummary? {
        let lines = source.split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).map(String.init)

        let id = captureValue(prefix: "id =", in: lines)
        let date = captureValue(prefix: "date =", in: lines)
        let alias = captureValue(prefix: "use alias", in: lines)
        let code = captureValue(prefix: "use code", in: lines)

        let summary = ECSourceBlockSummary(
            id: id,
            date: date,
            alias: alias,
            code: code
        )

        return summary.compactDescription == nil ? nil : summary
    }

    private static func captureValue(
        prefix: String,
        in lines: [String]
    ) -> String? {
        for line in lines {
            let scan = stripLineComment(from: line)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard scan.hasPrefix(prefix) else {
                continue
            }

            let value = scan.dropFirst(prefix.count)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !value.isEmpty {
                return value
            }
        }

        return nil
    }
}
