import Foundation

extension TaxonomyTester {
    public static func projectBalances(
        projectRoot: String
    ) -> [String: Decimal] {
        stderrPrint(
            "warning: projectBalances(projectRoot:) is a temporary shared diagnostics shim and should not become part of final reporting"
        )

        let rootURL = URL(fileURLWithPath: projectRoot)
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: nil
        ) else {
            return [:]
        }

        var balances: [String: Decimal] = [:]

        while let value = enumerator.nextObject() as? URL {
            guard value.pathExtension.lowercased() == "ec" else {
                continue
            }

            guard let text = try? String(contentsOf: value, encoding: .utf8) else {
                continue
            }

            for line in text.components(separatedBy: .newlines) {
                let trimmed = TaxonomyShared.trim(line)

                guard trimmed.contains("=") else {
                    continue
                }

                if let pair = parseSimpleBalanceLine(trimmed) {
                    balances[pair.code, default: 0] += pair.amount
                }
            }
        }

        return balances
    }
}

extension TaxonomyTester {
    public static func conceptsByCode(
        mappings: [TaxonomyCanonicalResolvedMapping]
    ) -> [String: Set<String>] {
        var out: [String: Set<String>] = [:]

        for mapping in mappings {
            out[mapping.matchedCode, default: []].insert(mapping.targetConcept)
        }

        return out
    }

    public static func parseSimpleBalanceLine(
        _ line: String
    ) -> (
        code: String,
        amount: Decimal
    )? {
        let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
        guard parts.count == 2 else {
            return nil
        }

        let lhs = TaxonomyShared.trim(parts[0])
        let rhs = TaxonomyShared.trim(parts[1])

        guard isLikelyCode(lhs) else {
            return nil
        }

        let normalizedAmount = rhs
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Decimal(
            string: normalizedAmount,
            locale: Locale(identifier: "en_US_POSIX")
        ) else {
            return nil
        }

        return (lhs, amount)
    }

    public static func isLikelyCode(
        _ value: String
    ) -> Bool {
        guard !value.isEmpty else {
            return false
        }

        let hasLetter = value.rangeOfCharacter(from: .letters) != nil
        let hasDigit = value.rangeOfCharacter(from: .decimalDigits) != nil

        return hasLetter || !hasDigit
    }
}
