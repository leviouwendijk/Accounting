import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension TaxonomyProbe {
    public static func stderrPrint(_ message: String) {
        let data = Data((message + "\n").utf8)
        FileHandle.standardError.write(data)
    }

    public static func localName(_ name: String?) -> String {
        guard let name else {
            return ""
        }

        if let idx = name.lastIndex(of: ":") {
            return String(name[name.index(after: idx)...])
        }

        return name
    }

    public static func attributeValue(_ attributes: [String: String], _ names: [String]) -> String? {
        for name in names {
            if let value = attributes[name] {
                return value
            }
        }

        for (key, value) in attributes {
            let keyLocal = localName(key)
            if names.contains(where: { localName($0) == keyLocal }) {
                return value
            }
        }

        return nil
    }

    public static func trim(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    public static func resolveURL(_ href: String, relativeTo base: URL) throws -> URL {
        if let absolute = URL(string: href), absolute.scheme != nil {
            return absolute
        }

        guard let resolved = URL(string: href, relativeTo: base)?.absoluteURL else {
            throw Error.invalidURL("href=\(href) relativeTo=\(base.absoluteString)")
        }

        return resolved
    }

    public static func conceptName(from locatorHref: String) -> String {
        if let url = URL(string: locatorHref), let fragment = url.fragment, !fragment.isEmpty {
            return fragment
        }

        if let hashIndex = locatorHref.lastIndex(of: "#") {
            let next = locatorHref.index(after: hashIndex)
            return String(locatorHref[next...])
        }

        return locatorHref
    }

    public static func fetchData(from url: URL) throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        }

        final class FetchBox: @unchecked Sendable {
            private let lock = NSLock()

            private var storedData: Data?
            private var storedResponse: URLResponse?
            private var storedError: Swift.Error?

            func store(
                data: Data?,
                response: URLResponse?,
                error: Swift.Error?
            ) {
                lock.lock()
                defer { lock.unlock() }

                storedData = data
                storedResponse = response
                storedError = error
            }

            func snapshot() -> (Data?, URLResponse?, Swift.Error?) {
                lock.lock()
                defer { lock.unlock() }

                return (storedData, storedResponse, storedError)
            }
        }

        let semaphore = DispatchSemaphore(value: 0)
        let box = FetchBox()

        let request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 60
        )

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            box.store(
                data: data,
                response: response,
                error: error
            )
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        let (capturedData, capturedResponse, capturedError) = box.snapshot()

        if let capturedError {
            throw Error.network(capturedError.localizedDescription)
        }

        if let http = capturedResponse as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw Error.http(http.statusCode, url.absoluteString)
        }

        guard let capturedData else {
            throw Error.network("no data returned for \(url.absoluteString)")
        }

        return capturedData
    }

    public static func fetchText(from url: URL) throws -> String {
        let data = try fetchData(from: url)

        if let string = String(data: data, encoding: .utf8) {
            return string
        }

        if let string = String(data: data, encoding: .isoLatin1) {
            return string
        }

        throw Error.parseFailed("could not decode text from \(url.absoluteString)")
    }

    public static func urlFromStringOrPath(_ value: String) throws -> URL {
        if let url = URL(string: value), url.scheme != nil {
            return url
        }

        if value.hasPrefix("/") {
            return URL(fileURLWithPath: value)
        }

        throw Error.invalidURL(value)
    }

    public static func writeTempFile(data: Data, suffix: String) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(suffix)

        do {
            try data.write(to: tempURL)
        } catch {
            throw Error.unableToWriteTempFile
        }

        return tempURL
    }

    public static func runCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
        let fileManager = FileManager.default

        let stdoutURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("stdout")

        let stderrURL = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("stderr")

        _ = fileManager.createFile(atPath: stdoutURL.path, contents: Data())
        _ = fileManager.createFile(atPath: stderrURL.path, contents: Data())

        let stdoutHandle = try FileHandle(forWritingTo: stdoutURL)
        let stderrHandle = try FileHandle(forWritingTo: stderrURL)

        defer {
            stdoutHandle.closeFile()
            stderrHandle.closeFile()
            try? fileManager.removeItem(at: stdoutURL)
            try? fileManager.removeItem(at: stderrURL)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = stdoutHandle
        process.standardError = stderrHandle

        try process.run()
        process.waitUntilExit()

        let stdoutData = try Data(contentsOf: stdoutURL)
        let stderrData = try Data(contentsOf: stderrURL)

        let stdout = String(data: stdoutData, encoding: .utf8)
            ?? String(decoding: stdoutData, as: UTF8.self)

        let stderr = String(data: stderrData, encoding: .utf8)
            ?? String(decoding: stderrData, as: UTF8.self)

        guard process.terminationStatus == 0 else {
            throw Error.commandFailed(
                "\(launchPath) \(arguments.joined(separator: " "))\n\(stderr)"
            )
        }

        return stdout
    }

    public static func unzipPath() throws -> String {
        let candidates = [
            "/usr/bin/unzip",
            "/bin/unzip"
        ]

        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }

        throw Error.commandUnavailable("Could not find an executable unzip binary")
    }
}

extension TaxonomyProbe {
    public static func normalizedMappingSourceIdentifier(_ raw: String) -> String {
        if raw.hasPrefix("rgs-i_") {
            return String(raw.dropFirst("rgs-i_".count))
        }

        if raw.hasPrefix("rgs-k_") {
            return String(raw.dropFirst("rgs-k_".count))
        }

        return raw
    }

    public static func loadCompiledChart(from url: URL) throws -> CompiledChart {
        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(CompiledChart.self, from: data)
        return try decoded.ensuringIndex(enrichNodes: true, strict: false)
    }

    public static func canonicalizeMappings(
        _ mappings: [ResolvedMapping],
        accounts: AccountStore
    ) -> (canonical: [CanonicalResolvedMapping], unresolved: [ResolvedMapping]) {
        var canonical: [CanonicalResolvedMapping] = []
        var unresolved: [ResolvedMapping] = []

        canonical.reserveCapacity(mappings.count)

        for mapping in mappings {
            let identifier = normalizedMappingSourceIdentifier(mapping.sourceConcept)

            if let node = accounts.byIdentifier[identifier] {
                canonical.append(
                    .init(
                        sourceLocatorLabel: mapping.sourceLocatorLabel,
                        sourceHref: mapping.sourceHref,
                        sourceConcept: mapping.sourceConcept,
                        sourceIdentifier: identifier,
                        sourceCode: node.codes.code,
                        targetDatapointLabel: mapping.targetDatapointLabel,
                        targetPrimaryQName: mapping.targetPrimaryQName,
                        dimensions: mapping.dimensions,
                        order: mapping.order
                    )
                )
                continue
            }

            if let node = accounts.byCode[identifier] {
                canonical.append(
                    .init(
                        sourceLocatorLabel: mapping.sourceLocatorLabel,
                        sourceHref: mapping.sourceHref,
                        sourceConcept: mapping.sourceConcept,
                        sourceIdentifier: identifier,
                        sourceCode: node.codes.code,
                        targetDatapointLabel: mapping.targetDatapointLabel,
                        targetPrimaryQName: mapping.targetPrimaryQName,
                        dimensions: mapping.dimensions,
                        order: mapping.order
                    )
                )
                continue
            }

            unresolved.append(mapping)
        }

        return (canonical, unresolved)
    }

    public static func sortDimensions(
        _ dimensions: [DimensionBinding]
    ) -> [DimensionBinding] {
        dimensions.sorted { lhs, rhs in
            if lhs.qname == rhs.qname {
                return (lhs.member ?? "") < (rhs.member ?? "")
            }

            return lhs.qname < rhs.qname
        }
    }

    public static func factKey(from mapping: CanonicalResolvedMapping) -> MappedFactKey {
        let dims = sortDimensions(
            mapping.dimensions.map {
                DimensionBinding(
                    qname: $0.qname,
                    member: $0.member
                )
            }
        )

        return .init(
            concept: mapping.targetPrimaryQName,
            dimensions: dims
        )
    }

    public static func compileMappedFacts(
        mappings: [CanonicalResolvedMapping],
        rgsBalances: [String: Decimal]
    ) -> [MappedFactKey: ComputedMappedFact] {
        var groupedMappings: [String: [CanonicalResolvedMapping]] = [:]

        for mapping in mappings {
            groupedMappings[mapping.sourceCode, default: []].append(mapping)
        }

        var out: [MappedFactKey: ComputedMappedFact] = [:]

        for (rgsCode, amount) in rgsBalances {
            guard amount != 0 else {
                continue
            }

            guard let matches = groupedMappings[rgsCode] else {
                continue
            }

            for mapping in matches {
                let key = factKey(from: mapping)

                if let existing = out[key] {
                    out[key] = .init(
                        key: key,
                        amount: existing.amount + amount,
                        matchedCodes: existing.matchedCodes + [rgsCode],
                        contributingMappings: existing.contributingMappings + [mapping]
                    )
                } else {
                    out[key] = .init(
                        key: key,
                        amount: amount,
                        matchedCodes: [rgsCode],
                        contributingMappings: [mapping]
                    )
                }
            }
        }

        return out
    }

    public static func unmatchedRGSCodes(
        mappings: [CanonicalResolvedMapping],
        rgsBalances: [String: Decimal]
    ) -> [String] {
        let mappedCodes = Set(mappings.map(\.sourceCode))

        return rgsBalances.keys
            .filter { (rgsBalances[$0] ?? 0) != 0 }
            .filter { !mappedCodes.contains($0) }
            .sorted()
    }

    public static func projectMappedFactsToConceptFacts(
        _ factsByKey: [MappedFactKey: ComputedMappedFact]
    ) -> [String: ComputedFact] {
        var out: [String: ComputedFact] = [:]

        for fact in factsByKey.values {
            let concept = fact.key.concept
            let uniqueMatched = Array(Set(fact.matchedCodes)).sorted()

            if let existing = out[concept] {
                out[concept] = .init(
                    concept: concept,
                    amount: existing.amount + fact.amount,
                    matchedCodes: Array(Set(existing.matchedCodes + uniqueMatched)).sorted(),
                    mappingLabel: "projected-from-generic-mapping"
                )
            } else {
                out[concept] = .init(
                    concept: concept,
                    amount: fact.amount,
                    matchedCodes: uniqueMatched,
                    mappingLabel: "projected-from-generic-mapping"
                )
            }
        }

        return out
    }
}

extension TaxonomyProbe {
    public static func mappingHitCountsByCode(
        mappings: [CanonicalResolvedMapping]
    ) -> [String: Int] {
        var out: [String: Int] = [:]

        for mapping in mappings {
            out[mapping.sourceCode, default: 0] += 1
        }

        return out
    }

    public static func renderDemoBalanceCoverage(
        mappings: [CanonicalResolvedMapping],
        rgsBalances: [String: Decimal],
        limitPerCode: Int = 12
    ) {
        let grouped = Dictionary(grouping: mappings, by: \.sourceCode)

        print("demo balance coverage:")

        for code in rgsBalances.keys.sorted() {
            let amount = rgsBalances[code] ?? 0
            let hits = grouped[code] ?? []

            print("  \(code) = \(decimalString(amount)) -> mappings: \(hits.count)")

            for mapping in hits.prefix(limitPerCode) {
                let dims = mapping.dimensions.map {
                    if let member = $0.member, !member.isEmpty {
                        return "\($0.qname)=\(member)"
                    } else {
                        return $0.qname
                    }
                }

                if dims.isEmpty {
                    print("    \(mapping.targetPrimaryQName)")
                } else {
                    print("    \(mapping.targetPrimaryQName) [\(dims.joined(separator: ", "))]")
                }
            }

            if hits.count > limitPerCode {
                print("    ... \(hits.count - limitPerCode) more")
            }
        }

        print("")
    }

    public static func renderCanonicalSourceCodes(
        mappings: [CanonicalResolvedMapping],
        prefix: String? = nil,
        limit: Int = 200
    ) {
        let codes = Array(Set(mappings.map(\.sourceCode))).sorted()

        let filtered: [String]
        if let prefix, !prefix.isEmpty {
            filtered = codes.filter { $0.hasPrefix(prefix) }
        } else {
            filtered = codes
        }

        print("canonical source codes: \(filtered.count)")

        for code in filtered.prefix(limit) {
            print("  \(code)")
        }

        if filtered.count > limit {
            print("  ... \(filtered.count - limit) more")
        }

        print("")
    }
}

extension TaxonomyProbe {
    public static func renderUsedProjectCoverage(
        mappings: [CanonicalResolvedMapping],
        balances: [String: Decimal],
        limitUnmatched: Int = 120
    ) {
        let mappedCodes = Set(mappings.map(\.sourceCode))
        let usedCodes = balances.keys.sorted()

        let matched = usedCodes.filter { mappedCodes.contains($0) }
        let unmatched = usedCodes.filter { !mappedCodes.contains($0) }

        print("project balance coverage:")
        print("  used codes: \(usedCodes.count)")
        print("  matched used codes: \(matched.count)")
        print("  unmatched used codes: \(unmatched.count)")
        print("")

        if !unmatched.isEmpty {
            print("unmatched used project codes:")
            for code in unmatched.prefix(limitUnmatched) {
                print("  \(code) = \(decimalString(balances[code] ?? 0))")
            }
            if unmatched.count > limitUnmatched {
                print("  ... \(unmatched.count - limitUnmatched) more")
            }
            print("")
        }
    }

    public static func projectBalances(
        projectRoot: URL
    ) throws -> (result: EntryCompileDriver.Result, balances: [String: Decimal]) {
        let compileResult = try EntryCompileDriver.compile(
            projectRoot: projectRoot,
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

        return (compileResult, balances)
    }

    public static func inspectUnmatchedProjectCodes(
        unmatchedCodes: [String],
        balances: [String: Decimal],
        accounts: AccountStore,
        mappings: [CanonicalResolvedMapping],
        resolvedEntries: [ResolvedEntry],
        limitEntriesPerCode: Int = 20
    ) {
        let mappedCodes = Set(mappings.map(\.sourceCode))

        var entryIDsByCode: [String: Set<String>] = [:]

        for (index, entry) in resolvedEntries.enumerated() {
            let entryLabel: String

            if let id = entry.id {
                entryLabel = String(id)
            } else {
                entryLabel = "index:\(index)"
            }

            for line in entry.lines {
                entryIDsByCode[line.account.code, default: []].insert(entryLabel)
            }
        }

        print("unmatched used project code inspection:")

        for code in unmatchedCodes {
            let amount = balances[code] ?? 0
            let existsInChart = accounts.byCode[code] != nil
            let existsInMappings = mappedCodes.contains(code)
            let entryIDs = Array(entryIDsByCode[code] ?? []).sorted()

            print("  \(code) = \(decimalString(amount))")
            print("    in chart: \(existsInChart)")
            print("    in taxonomy mappings: \(existsInMappings)")
            print("    used in entries: \(entryIDs.count)")

            if !entryIDs.isEmpty {
                // let shown = entryIDs.prefix(limitEntriesPerCode).map(String.init).joined(separator: ", ")
                let shown = entryIDs.prefix(limitEntriesPerCode).joined(separator: ", ")

                print("    entry ids: \(shown)")

                if entryIDs.count > limitEntriesPerCode {
                    print("    ... \(entryIDs.count - limitEntriesPerCode) more")
                }
            }
        }

        print("")
    }
}
