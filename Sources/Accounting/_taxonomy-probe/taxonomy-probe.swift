import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(FoundationXML)
import FoundationXML
#endif

public enum TaxonomyProbe {}

extension TaxonomyProbe {
    public struct LinkbaseRef {
        let href: String
        let role: String
    }

    public struct EntrypointRefs {
        var presentation: [LinkbaseRef] = []
        var labels: [LinkbaseRef] = []
        var definitions: [LinkbaseRef] = []
        var tables: [LinkbaseRef] = []
        var other: [LinkbaseRef] = []
    }

    public struct PresentationArc {
        let from: String
        let to: String
        let order: Double
    }

    public struct PresentationLink {
        let role: String
        let locs: [String: String]
        let arcs: [PresentationArc]
    }

    public struct LabelArc {
        let from: String
        let to: String
    }

    public struct MappingFile {
        let entrypoint: String?
        let rows: [MappingRow]
    }

    public struct MappingRow {
        let source: MappingSource
        let label: String
        let concept: String
        let dimensions: [String: String]
    }

    public enum MappingSource {
        case literal(String)
        case group([GroupTerm])
    }

    public struct GroupTerm {
        enum Op {
            case include
            case exclude
        }

        let op: Op
        let pattern: String
    }

    public struct ComputedFact {
        let concept: String
        let amount: Decimal
        let matchedCodes: [String]
        let mappingLabel: String
    }

    public enum Mode: String, Sendable {
        case probePackage
        case inspectGenericMapping
        case csvMapping
    }

    public struct Config: Sendable {
        public let entrypoint: String
        public let wantedPresentations: [String]
        public let mappingZIP: String
        public let mode: Mode
        public let probeKeywords: [String]
        public let probePatterns: [String]
        public let maxFilesToScan: Int
        public let maxHits: Int
        public let chartFile: String?
        public let balanceInput: BalanceInputMode
        public let projectRoot: String?
        public let demoRGSBalances: [String: Decimal]

        public init(
            entrypoint: String = "https://www.nltaxonomie.nl/nt20/bd/20251210/entrypoints/bd-rpt-ihz-aangifte-2025.xsd",
            wantedPresentations: [String] = [
                "winst-resultatenrekening-pre.xml",
                "winst-activa-pre.xml",
                "winst-passiva-pre.xml",
                "winst-berekening-pre.xml"
            ],
            mappingZIP: String = "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip",
            mode: Mode = .probePackage,
            probeKeywords: [String] = [
                "bd",
                "ihz",
                "aangifte",
                "rgs",
                "mapping",
                "entrypoint",
                "entrypoints",
                "presentation",
                "definition",
                "table",
                "label",
                "dictionary",
                "datapoint",
                "dimension",
                "linkbase"
            ],
            probePatterns: [String] = [
                "rgs-to-bd-rpt-ihz-aangifte-2025",
                "bd-rpt-ihz-aangifte-2025",
                "bd-ihz-aangifte",
                "map-bd-ihz",
                "mapping/",
                "entrypoints/",
                "presentation/",
                "definition/",
                "table/",
                "dictionary/",
                "linkbaseRef",
                "rgs-i_",
                "bd-i_"
            ],
            maxFilesToScan: Int = 400,
            maxHits: Int = 80,
            chartFile: String? = nil,
            balanceInput: BalanceInputMode = .demo,
            projectRoot: String? = nil,
            demoRGSBalances: [String: Decimal] = [
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
        ) {
            self.entrypoint = entrypoint
            self.wantedPresentations = wantedPresentations
            self.mappingZIP = mappingZIP
            self.mode = mode
            self.probeKeywords = probeKeywords
            self.probePatterns = probePatterns
            self.maxFilesToScan = maxFilesToScan
            self.maxHits = maxHits
            self.chartFile = chartFile
            self.balanceInput = balanceInput
            self.projectRoot = projectRoot
            self.demoRGSBalances = demoRGSBalances
        }
    }

    public struct Bootstrap {
        public let entrypointURL: URL
        public let entrypointBasename: String
        public let refs: EntrypointRefs

        public let selectedPresentationURLs: [URL]
        public let selectedLinks: [PresentationLink]

        public let allPresentationLinksByURL: [String: [PresentationLink]]

        public let labelsByConcept: [String: String]
    }

    enum Error: Swift.Error, CustomStringConvertible {
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
        case missingChartFile

        public var description: String {
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
            case .missingChartFile:
                return
                    "inspectGenericMapping requires a compiled chart JSON via chartFile / --chart"
            }
        }
    }

    public struct Runner: Sendable {
        public let config: Config

        public init(config: Config = .init()) {
            self.config = config
        }

        public func run() throws {
            let bootstrap = try loadBootstrap()

            print("entrypoint: \(bootstrap.entrypointURL.absoluteString)")
            print("")
            print("discovery:")
            print("  presentation refs: \(bootstrap.refs.presentation.count)")
            print("  label refs: \(bootstrap.refs.labels.count)")
            print("  definition refs: \(bootstrap.refs.definitions.count)")
            print("  table refs: \(bootstrap.refs.tables.count)")
            print("  other refs: \(bootstrap.refs.other.count)")
            print("")
            print("selected presentations: \(bootstrap.selectedPresentationURLs.count)")
            for url in bootstrap.selectedPresentationURLs {
                print("  \(url.absoluteString)")
            }
            print("")
            print("presentationLink count: \(bootstrap.selectedLinks.count)")
            print("")
            print("all presentation refs:")
            for ref in bootstrap.refs.presentation {
                print("  \(ref.href)")
            }
            print("")
            print("all loaded presentation files: \(bootstrap.allPresentationLinksByURL.count)")
            print("")
            print("labels loaded: \(bootstrap.labelsByConcept.count)")
            print("")

            let mappingZIPURL = try TaxonomyProbe.urlFromStringOrPath(config.mappingZIP)
            print("fetching mapping zip: \(mappingZIPURL.absoluteString)")
            let mappingZIPData = try TaxonomyProbe.fetchData(from: mappingZIPURL)
            print("mapping zip bytes: \(mappingZIPData.count)")

            let mappingZIPFileURL = try TaxonomyProbe.writeTempFile(data: mappingZIPData, suffix: "zip")
            defer {
                try? FileManager.default.removeItem(at: mappingZIPFileURL)
            }

            print("mapping temp file: \(mappingZIPFileURL.path)")
            print("")

            switch config.mode {
            case .probePackage:
                try runPackageProbe(zipFileURL: mappingZIPFileURL)

            case .inspectGenericMapping:
                try runGenericMappingInspection(
                    zipFileURL: mappingZIPFileURL,
                    bootstrap: bootstrap
                )

            case .csvMapping:
                try runCSVMapping(
                    zipFileURL: mappingZIPFileURL,
                    bootstrap: bootstrap
                )
            }
        }

        public func loadBootstrap() throws -> Bootstrap {
            let entrypointURL = try TaxonomyProbe.urlFromStringOrPath(config.entrypoint)
            let entrypointBasename = entrypointURL.lastPathComponent

            let entrypointData = try TaxonomyProbe.fetchData(from: entrypointURL)
            let entrypointParser = EntrypointParser()
            let refs = try entrypointParser.parse(data: entrypointData)

            let presentationParser = PresentationParser()

            var selectedPresentationURLs: [URL] = []
            var selectedLinks: [PresentationLink] = []
            var allPresentationLinksByURL: [String: [PresentationLink]] = [:]

            for ref in refs.presentation {
                let url = try TaxonomyProbe.resolveURL(ref.href, relativeTo: entrypointURL)
                let data = try TaxonomyProbe.fetchData(from: url)
                let links = try presentationParser.parse(data: data)

                allPresentationLinksByURL[url.absoluteString] = links

                let isSelected = config.wantedPresentations.contains { wanted in
                    ref.href.contains(wanted) || url.lastPathComponent == wanted
                }

                if isSelected {
                    selectedPresentationURLs.append(url)
                    selectedLinks.append(contentsOf: links)
                }
            }

            guard !selectedPresentationURLs.isEmpty else {
                throw Error.missingPresentation(config.wantedPresentations.joined(separator: ", "))
            }

            let dictionaryLabelURLs: [URL] = [
                try TaxonomyProbe.resolveURL("../dictionary/bd-data-lab-nl.xml", relativeTo: entrypointURL),
                try TaxonomyProbe.resolveURL("../dictionary/bd-tuples-lab-nl.xml", relativeTo: entrypointURL)
            ]

            var labelsByConcept: [String: String] = [:]
            let labelParser = LabelParser()

            print("loading dictionary labels:")
            for labelURL in dictionaryLabelURLs {
                print("  - \(labelURL.absoluteString)")
                let data = try TaxonomyProbe.fetchData(from: labelURL)
                let part = try labelParser.parse(data: data)

                for (concept, label) in part {
                    if labelsByConcept[concept] == nil {
                        labelsByConcept[concept] = label
                    }
                }
            }

            return .init(
                entrypointURL: entrypointURL,
                entrypointBasename: entrypointBasename,
                refs: refs,
                selectedPresentationURLs: selectedPresentationURLs,
                selectedLinks: selectedLinks,
                allPresentationLinksByURL: allPresentationLinksByURL,
                labelsByConcept: labelsByConcept
            )
        }

        public func runPackageProbe(zipFileURL: URL) throws {
            print("listing zip entries...")
            let entries = try TaxonomyProbe.listZIPEntries(zipFileURL: zipFileURL)
            print("zip entries: \(entries.count)")
            print("")

            TaxonomyProbe.summarizeZIPEntries(entries)
            TaxonomyProbe.printMatchingZIPPaths(
                entries,
                keywords: config.probeKeywords
            )

            try TaxonomyProbe.findTextHitsInZIP(
                zipFileURL: zipFileURL,
                entries: entries,
                keywords: config.probeKeywords,
                patterns: config.probePatterns,
                maxFilesToScan: config.maxFilesToScan,
                maxHits: config.maxHits
            )
        }

        public func runGenericMappingInspection(
            zipFileURL: URL,
            bootstrap: Bootstrap
        ) throws {
            let entries = try TaxonomyProbe.listZIPEntries(zipFileURL: zipFileURL)

            let rgsEntrypointSuffix = "/entrypoints/rgs-to-\(bootstrap.entrypointBasename)"
            guard let rgsEntrypointPath = entries.first(where: { $0.hasSuffix(rgsEntrypointSuffix) }) else {
                throw Error.parseFailed("Could not find RGS mapping entrypoint for \(bootstrap.entrypointBasename)")
            }

            print("rgs mapping entrypoint inside zip: \(rgsEntrypointPath)")
            print("")

            let rgsEntrypointText = try TaxonomyProbe.readZIPEntryText(
                zipFileURL: zipFileURL,
                entryPath: rgsEntrypointPath
            )

            guard let rgsEntrypointData = rgsEntrypointText.data(using: .utf8) else {
                throw Error.parseFailed("Could not UTF-8 decode RGS mapping entrypoint")
            }

            // let entrypointParser = EntrypointParser()
            // let rgsRefs = try entrypointParser.parse(data: rgsEntrypointData)

            // let mappingRefs = rgsRefs.other.filter { ref in
            //     ref.href.contains("mapping/")
            // }

            // print("mapping refs in RGS entrypoint: \(mappingRefs.count)")
            // for ref in mappingRefs {
            //     print("  \(ref.href)")
            // }
            // print("")

            let entrypointParser = EntrypointParser()
            let rgsRefs = try entrypointParser.parse(data: rgsEntrypointData)

            print("RGS entrypoint discovery:")
            print("  presentation refs: \(rgsRefs.presentation.count)")
            print("  label refs: \(rgsRefs.labels.count)")
            print("  definition refs: \(rgsRefs.definitions.count)")
            print("  table refs: \(rgsRefs.tables.count)")
            print("  other refs: \(rgsRefs.other.count)")
            print("")

            func printRefs(_ title: String, _ refs: [LinkbaseRef]) {
                guard !refs.isEmpty else {
                    return
                }

                print(title)
                for ref in refs {
                    print("  role: \(ref.role)")
                    print("  href: \(ref.href)")
                }
                print("")
            }

            printRefs("RGS presentation refs:", rgsRefs.presentation)
            printRefs("RGS label refs:", rgsRefs.labels)
            printRefs("RGS definition refs:", rgsRefs.definitions)
            printRefs("RGS table refs:", rgsRefs.tables)
            printRefs("RGS other refs:", rgsRefs.other)

            let mappingRefs = rgsRefs.other.filter { ref in
                ref.href.contains("mapping/")
            }

            print("mapping refs in RGS entrypoint: \(mappingRefs.count)")
            for ref in mappingRefs {
                print("  \(ref.href)")
            }
            print("")

            let parser = GenericLinkbaseParser()
            var allMappings: [ResolvedMapping] = []

            for ref in mappingRefs {
                let entryPath = try TaxonomyProbe.resolveZIPEntryPath(
                    ref.href,
                    relativeTo: rgsEntrypointPath
                )

                print("reading mapping XML: \(entryPath)")

                let xmlText = try TaxonomyProbe.readZIPEntryText(
                    zipFileURL: zipFileURL,
                    entryPath: entryPath
                )

                guard let xmlData = xmlText.data(using: .utf8) else {
                    throw Error.parseFailed("Could not UTF-8 decode mapping XML: \(entryPath)")
                }

                let linkbase = try parser.parse(data: xmlData)
                let mappings = TaxonomyProbe.resolveMappings(from: linkbase)

                print("  roleRefs: \(linkbase.roleRefs.count)")
                print("  arcroleRefs: \(linkbase.arcroleRefs.count)")
                print("  links: \(linkbase.links.count)")
                print("  resolved mappings: \(mappings.count)")
                print("")

                allMappings.append(contentsOf: mappings)
            }

            print("resolved mappings total: \(allMappings.count)")
            print("")

            let accounts: AccountStore
            let inputBalances: [String: Decimal]
            var projectCompileResult: EntryCompileDriver.Result?

            switch config.balanceInput {
            case .demo:
                guard let chartFile = config.chartFile else {
                    throw Error.missingChartFile
                }

                let chartURL = try TaxonomyProbe.urlFromStringOrPath(chartFile)
                let chart = try TaxonomyProbe.loadCompiledChart(from: chartURL)

                accounts = try AccountStore(chart: chart)
                inputBalances = config.demoRGSBalances

                print("balance input: demo")
                print("demo balance count: \(inputBalances.count)")
                print("")

            case .project:
                guard let rawProjectRoot = config.projectRoot else {
                    throw Error.parseFailed("balanceInput=project requires projectRoot")
                }

                let projectRootURL = URL(fileURLWithPath: rawProjectRoot, isDirectory: true)
                let projectData = try TaxonomyProbe.projectBalances(projectRoot: projectRootURL)

                projectCompileResult = projectData.result
                accounts = projectData.result.accounts
                inputBalances = projectData.balances

                print("balance input: project")
                print("project root: \(projectRootURL.path)")
                print("compiled resolved entries: \(projectData.result.resolved.count)")
                print("compiled project accounts: \(projectData.result.accounts.byCode.count)")
                print("project-derived balances loaded: \(inputBalances.count)")
                print("")
            }

            let canonicalization = TaxonomyProbe.canonicalizeMappings(
                allMappings,
                accounts: accounts
            )

            let canonicalMappings = canonicalization.canonical
            let unresolvedMappings = canonicalization.unresolved

            print("canonical mappings: \(canonicalMappings.count)")
            print("unresolved mapping identifiers: \(unresolvedMappings.count)")

            if !unresolvedMappings.isEmpty {
                let unresolvedIds = Array(
                    Set(
                        unresolvedMappings.map {
                            TaxonomyProbe.normalizedMappingSourceIdentifier($0.sourceConcept)
                        }
                    )
                ).sorted()

                for value in unresolvedIds.prefix(80) {
                    print("  unresolved: \(value)")
                }

                if unresolvedIds.count > 80 {
                    print("  ... \(unresolvedIds.count - 80) more")
                }
            }
            print("")

            switch config.balanceInput {
            case .demo:
                TaxonomyProbe.renderDemoBalanceCoverage(
                    mappings: canonicalMappings,
                    rgsBalances: inputBalances
                )

                TaxonomyProbe.renderCanonicalSourceCodes(
                    mappings: canonicalMappings,
                    prefix: "W",
                    limit: 300
                )

            case .project:
                TaxonomyProbe.renderUsedProjectCoverage(
                    mappings: canonicalMappings,
                    balances: inputBalances
                )
            }

            let factsByKey = TaxonomyProbe.compileMappedFacts(
                mappings: canonicalMappings,
                rgsBalances: inputBalances
            )

            let factsByConcept = TaxonomyProbe.projectMappedFactsToConceptFacts(factsByKey)
            let unmatchedCodes = TaxonomyProbe.unmatchedRGSCodes(
                mappings: canonicalMappings,
                rgsBalances: inputBalances
            )

            let selectedPresentationConcepts = TaxonomyProbe.presentationConcepts(
                from: bootstrap.selectedLinks
            )

            let conceptFactsNotInSelectedPresentation =
                Set(factsByConcept.keys).subtracting(selectedPresentationConcepts).sorted()

            print("selected presentation concepts: \(selectedPresentationConcepts.count)")
            print("projected concept facts: \(factsByConcept.count)")
            print("projected concept facts not in selected presentation: \(conceptFactsNotInSelectedPresentation.count)")

            for concept in conceptFactsNotInSelectedPresentation.prefix(200) {
                print("  \(concept)")
            }

            if conceptFactsNotInSelectedPresentation.count > 200 {
                print("  ... \(conceptFactsNotInSelectedPresentation.count - 200) more")
            }

            print("")

            var allBDPresentationConcepts: Set<String> = []

            for links in bootstrap.allPresentationLinksByURL.values {
                allBDPresentationConcepts.formUnion(
                    TaxonomyProbe.presentationConcepts(from: links)
                )
            }

            let conceptFactsOutsideAllBDPresentations =
                Set(factsByConcept.keys).subtracting(allBDPresentationConcepts).sorted()

            print("all BD presentation concepts: \(allBDPresentationConcepts.count)")
            print("projected concept facts outside all BD presentations: \(conceptFactsOutsideAllBDPresentations.count)")

            for concept in conceptFactsOutsideAllBDPresentations.prefix(200) {
                print("  \(concept)")
            }

            if conceptFactsOutsideAllBDPresentations.count > 200 {
                print("  ... \(conceptFactsOutsideAllBDPresentations.count - 200) more")
            }

            print("")

            switch config.balanceInput {
            case .demo:
                print("input balances:")
                for key in inputBalances.keys.sorted() {
                    print("  \(key) = \(TaxonomyProbe.decimalString(inputBalances[key] ?? 0))")
                }
                print("")

            case .project:
                print("input balances used for mapping: \(inputBalances.count)")
                print("")
            }

            if unmatchedCodes.isEmpty {
                print("unmatched RGS codes: 0")
            } else {
                print("unmatched RGS codes: \(unmatchedCodes.count)")
                for code in unmatchedCodes.prefix(200) {
                    print("  \(code)")
                }

                if unmatchedCodes.count > 200 {
                    print("  ... \(unmatchedCodes.count - 200) more")
                }
            }
            print("")

            if config.balanceInput == .project,
               let compileResult = projectCompileResult,
               !unmatchedCodes.isEmpty {
                TaxonomyProbe.inspectUnmatchedProjectCodes(
                    unmatchedCodes: unmatchedCodes,
                    balances: inputBalances,
                    accounts: accounts,
                    mappings: canonicalMappings,
                    resolvedEntries: compileResult.resolved
                )
            }

            if !unmatchedCodes.isEmpty {
                TaxonomyProbe.renderMappingSuggestions(
                    unmatchedCodes: unmatchedCodes,
                    mappings: canonicalMappings
                )
            }

            if !unmatchedCodes.isEmpty {
                TaxonomyProbe.renderCanonicalMappings(
                    mappings: canonicalMappings,
                    prefix: "WBedKan"
                )

                TaxonomyProbe.renderCanonicalMappings(
                    mappings: canonicalMappings,
                    prefix: "WBedOvpW"
                )
            }

            TaxonomyProbe.renderComputedMappedFacts(factsByKey, limit: 200)
            print("")

            print("projected presentation facts: \(factsByConcept.count)")
            print("")

            for link in bootstrap.selectedLinks {
                TaxonomyProbe.renderPresentationLink(
                    link,
                    labelsByConcept: bootstrap.labelsByConcept,
                    factsByConcept: factsByConcept
                )
                print("")
            }
        }

        public func runCSVMapping(
            zipFileURL: URL,
            bootstrap: Bootstrap
        ) throws {
            let (mappingEntryPath, mappingText) = try TaxonomyProbe.extractMatchingMappingCSV(
                zipFileURL: zipFileURL,
                entrypointBasename: bootstrap.entrypointBasename
            )
            print("selected mapping CSV inside zip: \(mappingEntryPath)")
            print("mapping csv bytes: \(mappingText.utf8.count)")
            print("")

            let mappingFile = try TaxonomyProbe.parseMappingCSV(mappingText)
            print("mapping entrypoint: \(mappingFile.entrypoint ?? "(none)")")
            print("mapping rows: \(mappingFile.rows.count)")
            print("")

            let factsByConcept = TaxonomyProbe.compileFacts(
                mappingRows: mappingFile.rows,
                rgsBalances: config.demoRGSBalances
            )

            print("demo RGS balances:")
            for key in config.demoRGSBalances.keys.sorted() {
                print("  \(key) = \(TaxonomyProbe.decimalString(config.demoRGSBalances[key] ?? 0))")
            }
            print("")

            print("compiled facts:")
            for key in factsByConcept.keys.sorted() {
                guard let fact = factsByConcept[key] else {
                    continue
                }
                print("  \(fact.concept) = \(TaxonomyProbe.decimalString(fact.amount))")
                print("    label: \(fact.mappingLabel)")
                if !fact.matchedCodes.isEmpty {
                    print("    matched: \(fact.matchedCodes.joined(separator: ", "))")
                }
            }
            print("")

            for link in bootstrap.selectedLinks {
                TaxonomyProbe.renderPresentationLink(
                    link,
                    labelsByConcept: bootstrap.labelsByConcept,
                    factsByConcept: factsByConcept
                )
                print("")
            }
        }
    }
}

extension TaxonomyProbe {
    public enum BalanceInputMode: String, Sendable {
        case demo
        case project
    }
}
