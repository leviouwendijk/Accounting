import Foundation

extension TaxonomyProbe {
    static func splitSemicolonLine(_ line: String) -> [String] {
        line.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
    }

    static func parseMappingSource(_ raw: String) -> MappingSource {
        let value = trim(raw)

        if value.hasPrefix("=GROUP("), value.hasSuffix(")") {
            let start = value.index(value.startIndex, offsetBy: 7)
            let end = value.index(before: value.endIndex)
            let inner = String(value[start..<end])

            var terms: [GroupTerm] = []
            var current = ""
            var currentOp: GroupTerm.Op = .include

            for character in inner {
                if character == "+" || character == "-" {
                    let pattern = trim(current)
                    if !pattern.isEmpty {
                        terms.append(.init(op: currentOp, pattern: pattern))
                    }
                    current = ""
                    currentOp = (character == "+") ? .include : .exclude
                } else {
                    current.append(character)
                }
            }

            let finalPattern = trim(current)
            if !finalPattern.isEmpty {
                terms.append(.init(op: currentOp, pattern: finalPattern))
            }

            return .group(terms)
        }

        return .literal(value)
    }

    static func parseMappingCSV(_ text: String) throws -> MappingFile {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        var entrypoint: String?
        var header: [String]?
        var rows: [MappingRow] = []

        for rawLine in lines {
            let line = trim(rawLine)
            if line.isEmpty {
                continue
            }

            if line.hasPrefix("SBR_ENTRYPOINT;") {
                let fields = splitSemicolonLine(line)
                if fields.count >= 2 {
                    entrypoint = trim(fields[1])
                }
                continue
            }

            if line.hasPrefix("SBR_CONNECT;") {
                header = splitSemicolonLine(line)
                continue
            }

            guard let header else {
                continue
            }

            let fields = splitSemicolonLine(line)
            var rowDict: [String: String] = [:]

            for (index, key) in header.enumerated() {
                let value = index < fields.count ? fields[index] : ""
                rowDict[key] = trim(value)
            }

            guard let rawSource = rowDict["SBR_CONNECT"] else {
                throw Error.missingColumn("SBR_CONNECT")
            }
            guard let label = rowDict["SBR_LABEL"] else {
                throw Error.missingColumn("SBR_LABEL")
            }
            guard let concept = rowDict["SBR_CONCEPT"] else {
                throw Error.missingColumn("SBR_CONCEPT")
            }

            var dimensions: [String: String] = [:]
            for (key, value) in rowDict {
                if key.hasPrefix("SBR_AXIS["), !value.isEmpty {
                    dimensions[key] = value
                }
            }

            rows.append(
                .init(
                    source: parseMappingSource(rawSource),
                    label: label,
                    concept: concept,
                    dimensions: dimensions
                )
            )
        }

        guard header != nil else {
            throw Error.missingMappingHeader
        }

        return .init(entrypoint: entrypoint, rows: rows)
    }

    static func globMatch(pattern: String, text: String) -> Bool {
        let p = Array(pattern)
        let t = Array(text)

        func rec(_ pi: Int, _ ti: Int) -> Bool {
            if pi == p.count {
                return ti == t.count
            }

            let pc = p[pi]

            if pc == "*" {
                var scan = ti
                while true {
                    if rec(pi + 1, scan) {
                        return true
                    }
                    if scan == t.count {
                        break
                    }
                    scan += 1
                }
                return false
            }

            if ti == t.count {
                return false
            }

            if pc == "?" || pc == t[ti] {
                return rec(pi + 1, ti + 1)
            }

            return false
        }

        return rec(0, 0)
    }

    static func compileFacts(
        mappingRows: [MappingRow],
        rgsBalances: [String: Decimal]
    ) -> [String: ComputedFact] {
        var out: [String: ComputedFact] = [:]

        for row in mappingRows {
            switch row.source {
            case .literal:
                continue

            case .group(let terms):
                var amount: Decimal = 0
                var matched: [String] = []

                let sortedCodes = rgsBalances.keys.sorted()

                for term in terms {
                    let termMatches = sortedCodes.filter { globMatch(pattern: term.pattern, text: $0) }

                    for code in termMatches {
                        let value = rgsBalances[code] ?? 0

                        switch term.op {
                        case .include:
                            amount += value
                        case .exclude:
                            amount -= value
                        }

                        matched.append("\(term.op == .include ? "+" : "-")\(code)")
                    }
                }

                out[row.concept] = .init(
                    concept: row.concept,
                    amount: amount,
                    matchedCodes: matched,
                    mappingLabel: row.label
                )
            }
        }

        return out
    }
}
