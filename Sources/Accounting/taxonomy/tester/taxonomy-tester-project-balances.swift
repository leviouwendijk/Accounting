import Foundation

extension TaxonomyTester {
    public static func projectBalances(
        projectRoot: String
    ) throws -> [String: Decimal] {
        let rootURL = URL(
            fileURLWithPath: projectRoot,
            isDirectory: true
        )

        let compileResult = try EntryCompileDriver.compile(
            projectRoot: rootURL,
            setting: .init(
                entities: true,
                accounts: true,
                transactions: true,
                entries: true,
                assertion: true,
                loc_trace: false
            ),
            verbose: false
        )

        let rows = trialBalance(compileResult.resolved)

        var balances: [String: Decimal] = [:]
        balances.reserveCapacity(rows.count)

        for row in rows {
            let net = row.net
            guard net != 0 else {
                continue
            }

            balances[row.accountCode] = net
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
