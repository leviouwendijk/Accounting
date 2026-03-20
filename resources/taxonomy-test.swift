#!/usr/bin/env swift

import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(FoundationXML)
import FoundationXML
#endif

// MARK: - Models

struct LinkbaseRef {
    let href: String
    let role: String
}

struct EntrypointRefs {
    var presentation: [LinkbaseRef] = []
    var labels: [LinkbaseRef] = []
    var definitions: [LinkbaseRef] = []
    var tables: [LinkbaseRef] = []
    var other: [LinkbaseRef] = []
}

struct PresentationArc {
    let from: String
    let to: String
    let order: Double
}

struct PresentationLink {
    let role: String
    let locs: [String: String]
    let arcs: [PresentationArc]
}

struct LabelArc {
    let from: String
    let to: String
}

struct MappingFile {
    let entrypoint: String?
    let rows: [MappingRow]
}

struct MappingRow {
    let source: MappingSource
    let label: String
    let concept: String
    let dimensions: [String: String]
}

enum MappingSource {
    case literal(String)
    case group([GroupTerm])
}

struct GroupTerm {
    enum Op {
        case include
        case exclude
    }

    let op: Op
    let pattern: String
}

struct ComputedFact {
    let concept: String
    let amount: Decimal
    let matchedCodes: [String]
    let mappingLabel: String
}

// MARK: - Errors

enum ScriptError: Error, CustomStringConvertible {
    case invalidURL(String)
    case network(String)
    case http(Int, String)
    case parseFailed(String)
    case missingPresentation(String)
    case missingMappingHeader
    case missingColumn(String)
    case commandFailed(String)
    case commandUnavailable(String)
    case mappingCSVNotFound(String)
    case unableToWriteTempFile

    var description: String {
        switch self {
        case .invalidURL(let value):
            return "Invalid URL: \(value)"
        case .network(let value):
            return "Network error: \(value)"
        case .http(let status, let url):
            return "HTTP \(status): \(url)"
        case .parseFailed(let value):
            return "XML parse failed: \(value)"
        case .missingPresentation(let value):
            return "Could not find presentation linkbase matching: \(value)"
        case .missingMappingHeader:
            return "Missing mapping CSV header"
        case .missingColumn(let value):
            return "Missing required CSV column: \(value)"
        case .commandFailed(let value):
            return "Command failed: \(value)"
        case .commandUnavailable(let value):
            return "Command unavailable: \(value)"
        case .mappingCSVNotFound(let value):
            return "Could not find mapping CSV for entrypoint basename: \(value)"
        case .unableToWriteTempFile:
            return "Unable to write temporary file"
        }
    }
}

// MARK: - Utilities

func stderrPrint(_ message: String) {
    let data = Data((message + "\n").utf8)
    FileHandle.standardError.write(data)
}

func localName(_ name: String?) -> String {
    guard let name else {
        return ""
    }

    if let idx = name.lastIndex(of: ":") {
        return String(name[name.index(after: idx)...])
    }

    return name
}

func attributeValue(_ attributes: [String: String], _ names: [String]) -> String? {
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

func trim(_ value: String) -> String {
    value.trimmingCharacters(in: .whitespacesAndNewlines)
}

func decimalString(_ value: Decimal) -> String {
    NSDecimalNumber(decimal: value).stringValue
}

func resolveURL(_ href: String, relativeTo base: URL) throws -> URL {
    if let absolute = URL(string: href), absolute.scheme != nil {
        return absolute
    }

    guard let resolved = URL(string: href, relativeTo: base)?.absoluteURL else {
        throw ScriptError.invalidURL("href=\(href) relativeTo=\(base.absoluteString)")
    }

    return resolved
}

func conceptName(from locatorHref: String) -> String {
    if let url = URL(string: locatorHref), let fragment = url.fragment, !fragment.isEmpty {
        return fragment
    }

    if let hashIndex = locatorHref.lastIndex(of: "#") {
        let next = locatorHref.index(after: hashIndex)
        return String(locatorHref[next...])
    }

    return locatorHref
}

func fetchData(from url: URL) throws -> Data {
    if url.isFileURL {
        return try Data(contentsOf: url)
    }

    let semaphore = DispatchSemaphore(value: 0)
    var capturedData: Data?
    var capturedResponse: URLResponse?
    var capturedError: Error?

    let request = URLRequest(
        url: url,
        cachePolicy: .reloadIgnoringLocalCacheData,
        timeoutInterval: 60
    )

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        capturedData = data
        capturedResponse = response
        capturedError = error
        semaphore.signal()
    }

    task.resume()
    semaphore.wait()

    if let capturedError {
        throw ScriptError.network(capturedError.localizedDescription)
    }

    if let http = capturedResponse as? HTTPURLResponse,
       !(200...299).contains(http.statusCode) {
        throw ScriptError.http(http.statusCode, url.absoluteString)
    }

    guard let capturedData else {
        throw ScriptError.network("no data returned for \(url.absoluteString)")
    }

    return capturedData
}

func fetchText(from url: URL) throws -> String {
    let data = try fetchData(from: url)

    if let string = String(data: data, encoding: .utf8) {
        return string
    }

    if let string = String(data: data, encoding: .isoLatin1) {
        return string
    }

    throw ScriptError.parseFailed("could not decode text from \(url.absoluteString)")
}

func urlFromStringOrPath(_ value: String) throws -> URL {
    if let url = URL(string: value), url.scheme != nil {
        return url
    }

    if value.hasPrefix("/") {
        return URL(fileURLWithPath: value)
    }

    throw ScriptError.invalidURL(value)
}

func writeTempFile(data: Data, suffix: String) throws -> URL {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathExtension(suffix)

    do {
        try data.write(to: tempURL)
    } catch {
        throw ScriptError.unableToWriteTempFile
    }

    return tempURL
}

func runCommand(_ launchPath: String, _ arguments: [String]) throws -> String {
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
        throw ScriptError.commandFailed(
            "\(launchPath) \(arguments.joined(separator: " "))\n\(stderr)"
        )
    }

    return stdout
}

func unzipPath() throws -> String {
    let candidates = [
        "/usr/bin/unzip",
        "/bin/unzip"
    ]

    for path in candidates {
        if FileManager.default.isExecutableFile(atPath: path) {
            return path
        }
    }

    throw ScriptError.commandUnavailable("Could not find an executable unzip binary")
}

// MARK: - XML Parsers

final class EntrypointParser: NSObject, XMLParserDelegate {
    private(set) var refs = EntrypointRefs()
    private var parseError: Error?

    func parse(data: Data) throws -> EntrypointRefs {
        refs = EntrypointRefs()
        parseError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw parseError ?? parser.parserError ?? ScriptError.parseFailed("unknown error")
        }

        return refs
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        let name = localName(qName ?? elementName)

        guard name == "linkbaseRef" else {
            return
        }

        guard let href = attributeValue(attributeDict, ["xlink:href", "href"]) else {
            return
        }

        let role = attributeValue(attributeDict, ["xlink:role", "role"]) ?? ""
        let ref = LinkbaseRef(href: href, role: role)

        if role.contains("presentationLinkbaseRef") || href.hasSuffix("-pre.xml") {
            refs.presentation.append(ref)
        } else if role.contains("labelLinkbaseRef") || href.hasSuffix("-lab.xml") {
            refs.labels.append(ref)
        } else if role.contains("definitionLinkbaseRef") || href.hasSuffix("-def.xml") {
            refs.definitions.append(ref)
        } else if href.hasSuffix("-tab.xml") {
            refs.tables.append(ref)
        } else {
            refs.other.append(ref)
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}

final class PresentationParser: NSObject, XMLParserDelegate {
    private(set) var links: [PresentationLink] = []

    private var currentRole: String?
    private var currentLocs: [String: String] = [:]
    private var currentArcs: [PresentationArc] = []
    private var parseError: Error?

    func parse(data: Data) throws -> [PresentationLink] {
        links = []
        currentRole = nil
        currentLocs = [:]
        currentArcs = []
        parseError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw parseError ?? parser.parserError ?? ScriptError.parseFailed("unknown error")
        }

        return links
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        let name = localName(qName ?? elementName)

        switch name {
        case "presentationLink":
            currentRole = attributeValue(attributeDict, ["xlink:role", "role"]) ?? "(no role)"
            currentLocs = [:]
            currentArcs = []

        case "loc":
            guard currentRole != nil else {
                return
            }

            guard let label = attributeValue(attributeDict, ["xlink:label", "label"]),
                  let href = attributeValue(attributeDict, ["xlink:href", "href"]) else {
                return
            }

            currentLocs[label] = href

        case "presentationArc":
            guard currentRole != nil else {
                return
            }

            guard let from = attributeValue(attributeDict, ["xlink:from", "from"]),
                  let to = attributeValue(attributeDict, ["xlink:to", "to"]) else {
                return
            }

            let order = Double(attributeValue(attributeDict, ["order"]) ?? "0") ?? 0
            currentArcs.append(.init(from: from, to: to, order: order))

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = localName(qName ?? elementName)

        guard name == "presentationLink" else {
            return
        }

        if let currentRole {
            links.append(
                .init(
                    role: currentRole,
                    locs: currentLocs,
                    arcs: currentArcs
                )
            )
        }

        currentRole = nil
        currentLocs = [:]
        currentArcs = []
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}

final class LabelParser: NSObject, XMLParserDelegate {
    private var parseError: Error?

    private var currentLocs: [String: String] = [:]
    private var currentArcs: [LabelArc] = []
    private var currentResources: [String: String] = [:]

    private var currentResourceLabel: String?
    private var currentResourceRole: String?
    private var currentText = ""

    private(set) var labelsByConcept: [String: String] = [:]

    func parse(data: Data) throws -> [String: String] {
        parseError = nil
        labelsByConcept = [:]
        currentLocs = [:]
        currentArcs = []
        currentResources = [:]
        currentResourceLabel = nil
        currentResourceRole = nil
        currentText = ""

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            throw parseError ?? parser.parserError ?? ScriptError.parseFailed("unknown error")
        }

        return labelsByConcept
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String]
    ) {
        let name = localName(qName ?? elementName)

        switch name {
        case "labelLink":
            currentLocs = [:]
            currentArcs = []
            currentResources = [:]

        case "loc":
            guard let label = attributeValue(attributeDict, ["xlink:label", "label"]),
                  let href = attributeValue(attributeDict, ["xlink:href", "href"]) else {
                return
            }

            currentLocs[label] = href

        case "labelArc":
            guard let from = attributeValue(attributeDict, ["xlink:from", "from"]),
                  let to = attributeValue(attributeDict, ["xlink:to", "to"]) else {
                return
            }

            currentArcs.append(.init(from: from, to: to))

        case "label":
            currentResourceLabel = attributeValue(attributeDict, ["xlink:label", "label"])
            currentResourceRole = attributeValue(attributeDict, ["xlink:role", "role"])
            currentText = ""

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentResourceLabel != nil {
            currentText.append(string)
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let name = localName(qName ?? elementName)

        switch name {
        case "label":
            if let resourceLabel = currentResourceLabel {
                let text = trim(currentText)
                let role = currentResourceRole ?? ""

                if !text.isEmpty {
                    let isNormalLabel =
                        role.isEmpty ||
                        role.hasSuffix("/label") ||
                        role.contains("label")

                    if isNormalLabel || currentResources[resourceLabel] == nil {
                        currentResources[resourceLabel] = text
                    }
                }
            }

            currentResourceLabel = nil
            currentResourceRole = nil
            currentText = ""

        case "labelLink":
            for arc in currentArcs {
                guard let href = currentLocs[arc.from],
                      let labelText = currentResources[arc.to] else {
                    continue
                }

                let concept = conceptName(from: href)
                if labelsByConcept[concept] == nil {
                    labelsByConcept[concept] = labelText
                }
            }

            currentLocs = [:]
            currentArcs = []
            currentResources = [:]

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
}

// MARK: - CSV Mapping

func splitSemicolonLine(_ line: String) -> [String] {
    line.split(separator: ";", omittingEmptySubsequences: false).map(String.init)
}

func parseMappingSource(_ raw: String) -> MappingSource {
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

func parseMappingCSV(_ text: String) throws -> MappingFile {
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
            throw ScriptError.missingColumn("SBR_CONNECT")
        }
        guard let label = rowDict["SBR_LABEL"] else {
            throw ScriptError.missingColumn("SBR_LABEL")
        }
        guard let concept = rowDict["SBR_CONCEPT"] else {
            throw ScriptError.missingColumn("SBR_CONCEPT")
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
        throw ScriptError.missingMappingHeader
    }

    return .init(entrypoint: entrypoint, rows: rows)
}

// MARK: - ZIP Mapping Fetch

func listZIPEntries(zipFileURL: URL) throws -> [String] {
    let unzip = try unzipPath()
    let output = try runCommand(unzip, ["-Z1", zipFileURL.path])
    return output
        .split(separator: "\n", omittingEmptySubsequences: true)
        .map(String.init)
}

func readZIPEntryText(zipFileURL: URL, entryPath: String) throws -> String {
    let unzip = try unzipPath()
    return try runCommand(unzip, ["-p", zipFileURL.path, entryPath])
}

func extractMatchingMappingCSV(
    zipFileURL: URL,
    entrypointBasename: String
) throws -> (entryPath: String, text: String) {
    print("listing zip entries...")
    let entries = try listZIPEntries(zipFileURL: zipFileURL)
    print("zip entries: \(entries.count)")

    let csvEntries = entries.filter { $0.lowercased().hasSuffix(".csv") }
    print("csv entries: \(csvEntries.count)")

    let prioritized = csvEntries.sorted { lhs, rhs in
        let lhsScore = (lhs.lowercased().contains("ihz") ? 0 : 1) + (lhs.lowercased().contains("aangifte") ? 0 : 1)
        let rhsScore = (rhs.lowercased().contains("ihz") ? 0 : 1) + (rhs.lowercased().contains("aangifte") ? 0 : 1)

        if lhsScore == rhsScore {
            return lhs < rhs
        }

        return lhsScore < rhsScore
    }

    for (index, entry) in prioritized.enumerated() {
        print("reading csv candidate \(index + 1)/\(prioritized.count): \(entry)")
        let text = try readZIPEntryText(zipFileURL: zipFileURL, entryPath: entry)

        if text.contains("SBR_ENTRYPOINT;") && text.contains(entrypointBasename) {
            print("matched mapping csv: \(entry)")
            return (entry, text)
        }
    }

    throw ScriptError.mappingCSVNotFound(entrypointBasename)
}

// MARK: - Glob Matching

func globMatch(pattern: String, text: String) -> Bool {
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

// MARK: - Fact Compilation

func compileFacts(
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

// MARK: - Tree Rendering

func renderPresentationLink(
    _ link: PresentationLink,
    labelsByConcept: [String: String],
    factsByConcept: [String: ComputedFact]
) {
    var childrenByFrom: [String: [(Double, String)]] = [:]
    var allFrom: Set<String> = []
    var allTo: Set<String> = []

    for arc in link.arcs {
        childrenByFrom[arc.from, default: []].append((arc.order, arc.to))
        allFrom.insert(arc.from)
        allTo.insert(arc.to)
    }

    let rootLabels = allFrom.subtracting(allTo).sorted()

    func printNode(_ locatorLabel: String, indent: Int, seen: inout Set<String>) {
        guard let href = link.locs[locatorLabel] else {
            return
        }

        let concept = conceptName(from: href)
        let label = labelsByConcept[concept]
        let prefix = String(repeating: " ", count: indent)

        if let fact = factsByConcept[concept] {
            if let label {
                print("\(prefix)- \(concept) — \(label) = \(decimalString(fact.amount))")
            } else {
                print("\(prefix)- \(concept) = \(decimalString(fact.amount))")
            }

            if !fact.matchedCodes.isEmpty {
                print("\(prefix)  matched: \(fact.matchedCodes.joined(separator: ", "))")
            }
        } else {
            if let label {
                print("\(prefix)- \(concept) — \(label)")
            } else {
                print("\(prefix)- \(concept)")
            }
        }

        if seen.contains(locatorLabel) {
            print("\(prefix)  [cycle detected]")
            return
        }

        seen.insert(locatorLabel)

        let children = (childrenByFrom[locatorLabel] ?? [])
            .sorted { lhs, rhs in
                if lhs.0 == rhs.0 {
                    return lhs.1 < rhs.1
                }
                return lhs.0 < rhs.0
            }
            .map(\.1)

        for child in children {
            printNode(child, indent: indent + 4, seen: &seen)
        }

        seen.remove(locatorLabel)
    }

    print("role: \(link.role)")
    print("roots: \(rootLabels.count)")

    for root in rootLabels {
        var seen: Set<String> = []
        printNode(root, indent: 0, seen: &seen)
    }
}

// MARK: - Configuration

// let entrypoint = "https://www.nltaxonomie.nl/nt20/bd/20251210.a/entrypoints/bd-rpt-ihz-aangifte-2025.xsd"
let entrypoint = "https://www.nltaxonomie.nl/nt20/bd/20251210/entrypoints/bd-rpt-ihz-aangifte-2025.xsd"
let wantedPresentation = "winst-resultatenrekening-pre.xml"

// Official separate RGS mapping package.
// let mappingZIP = "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/RGS3.8-mapping-naar-SBR-NT20-concepten.zip"
let mappingZIP = "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip"

// Demo source balances for the funnel proof.
let demoRGSBalances: [String: Decimal] = [
    "WOmzHan": 125000,
    "WVooMut": -3500,
    "WBedAutBrand": 1800,
    "WBedAutPark": 450,
    "WBedTraTrein": 220,
    "WBedHuiHuur": 12000,
    "WBedOndWerkpl": 900,
    "WBedVkkAds": 1400,
    "WBedOvpBank": 380,
    "WFbeRlmObr": 760
]

// MARK: - Main

do {
    let entrypointURL = try urlFromStringOrPath(entrypoint)
    let entrypointBasename = entrypointURL.lastPathComponent

    let entrypointData = try fetchData(from: entrypointURL)
    let entrypointParser = EntrypointParser()
    let refs = try entrypointParser.parse(data: entrypointData)

    print("entrypoint: \(entrypointURL.absoluteString)")
    print("")
    print("discovery:")
    print("  presentation refs: \(refs.presentation.count)")
    print("  label refs: \(refs.labels.count)")
    print("  definition refs: \(refs.definitions.count)")
    print("  table refs: \(refs.tables.count)")
    print("  other refs: \(refs.other.count)")
    print("")

    guard let chosenPresentationRef = refs.presentation.first(where: { $0.href.contains(wantedPresentation) }) else {
        throw ScriptError.missingPresentation(wantedPresentation)
    }

    let presentationURL = try resolveURL(chosenPresentationRef.href, relativeTo: entrypointURL)
    print("selected presentation: \(presentationURL.absoluteString)")
    print("")

    let presentationData = try fetchData(from: presentationURL)
    let presentationParser = PresentationParser()
    let links = try presentationParser.parse(data: presentationData)

    print("presentationLink count: \(links.count)")
    print("")

    // Labels are not exposed by this entrypoint as direct linkbase refs,
    // so fetch the Belastingdienst dictionary label files directly.
    let dictionaryLabelURLs: [URL] = [
        try resolveURL("../dictionary/bd-data-lab-nl.xml", relativeTo: entrypointURL),
        try resolveURL("../dictionary/bd-tuples-lab-nl.xml", relativeTo: entrypointURL)
    ]

    var labelsByConcept: [String: String] = [:]
    let labelParser = LabelParser()

    print("loading dictionary labels:")
    for labelURL in dictionaryLabelURLs {
        print("  - \(labelURL.absoluteString)")
        let data = try fetchData(from: labelURL)
        let part = try labelParser.parse(data: data)

        for (concept, label) in part {
            if labelsByConcept[concept] == nil {
                labelsByConcept[concept] = label
            }
        }
    }
    print("labels loaded: \(labelsByConcept.count)")
    print("")

    let mappingZIPURL = try urlFromStringOrPath(mappingZIP)

    print("fetching mapping zip: \(mappingZIPURL.absoluteString)")
    let mappingZIPData = try fetchData(from: mappingZIPURL)
    print("mapping zip bytes: \(mappingZIPData.count)")

    let mappingZIPFileURL = try writeTempFile(data: mappingZIPData, suffix: "zip")
    defer {
        try? FileManager.default.removeItem(at: mappingZIPFileURL)
    }

    print("mapping temp file: \(mappingZIPFileURL.path)")
    let (mappingEntryPath, mappingText) = try extractMatchingMappingCSV(
        zipFileURL: mappingZIPFileURL,
        entrypointBasename: entrypointBasename
    )
    print("selected mapping CSV inside zip: \(mappingEntryPath)")
    print("mapping csv bytes: \(mappingText.utf8.count)")
    print("")

    let mappingFile = try parseMappingCSV(mappingText)
    print("mapping entrypoint: \(mappingFile.entrypoint ?? "(none)")")
    print("mapping rows: \(mappingFile.rows.count)")
    print("")

    let factsByConcept = compileFacts(
        mappingRows: mappingFile.rows,
        rgsBalances: demoRGSBalances
    )

    print("demo RGS balances:")
    for key in demoRGSBalances.keys.sorted() {
        print("  \(key) = \(decimalString(demoRGSBalances[key] ?? 0))")
    }
    print("")

    print("compiled facts:")
    for key in factsByConcept.keys.sorted() {
        guard let fact = factsByConcept[key] else {
            continue
        }
        print("  \(fact.concept) = \(decimalString(fact.amount))")
        print("    label: \(fact.mappingLabel)")
        if !fact.matchedCodes.isEmpty {
            print("    matched: \(fact.matchedCodes.joined(separator: ", "))")
        }
    }
    print("")

    for link in links {
        renderPresentationLink(
            link,
            labelsByConcept: labelsByConcept,
            factsByConcept: factsByConcept
        )
        print("")
    }
} catch {
    stderrPrint("error: \(error)")
}
