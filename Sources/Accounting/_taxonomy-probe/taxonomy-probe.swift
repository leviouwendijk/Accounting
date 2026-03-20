import Foundation
import Dispatch

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(FoundationXML)
import FoundationXML
#endif

enum TaxonomyProbe {}

extension TaxonomyProbe {
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

    enum Mode: String, Sendable {
        case probePackage
        case csvMapping
    }

    struct Config: Sendable {
        let entrypoint: String
        let wantedPresentation: String
        let mappingZIP: String
        let mode: Mode
        let probeKeywords: [String]
        let probePatterns: [String]
        let maxFilesToScan: Int
        let maxHits: Int
        let demoRGSBalances: [String: Decimal]

        init(
            entrypoint: String = "https://www.nltaxonomie.nl/nt20/bd/20251210/entrypoints/bd-rpt-ihz-aangifte-2025.xsd",
            wantedPresentation: String = "winst-resultatenrekening-pre.xml",
            mappingZIP: String = "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip",
            mode: Mode = .probePackage,
            probeKeywords: [String] = ["bd", "ihz", "aangifte", "rgs", "mapping", "connect"],
            probePatterns: [String] = [
                "bd-rpt-ihz-aangifte-2025",
                "bd-ihz-aangifte",
                "bd-i_turnovernetfiscal",
                "bd-i_",
                "rgs"
            ],
            maxFilesToScan: Int = 400,
            maxHits: Int = 80,
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
            self.wantedPresentation = wantedPresentation
            self.mappingZIP = mappingZIP
            self.mode = mode
            self.probeKeywords = probeKeywords
            self.probePatterns = probePatterns
            self.maxFilesToScan = maxFilesToScan
            self.maxHits = maxHits
            self.demoRGSBalances = demoRGSBalances
        }
    }

    struct Bootstrap {
        let entrypointURL: URL
        let entrypointBasename: String
        let refs: EntrypointRefs
        let presentationURL: URL
        let links: [PresentationLink]
        let labelsByConcept: [String: String]
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

    struct Runner: Sendable {
        let config: Config

        init(config: Config = .init()) {
            self.config = config
        }

        func run() throws {
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
            print("selected presentation: \(bootstrap.presentationURL.absoluteString)")
            print("")
            print("presentationLink count: \(bootstrap.links.count)")
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

            case .csvMapping:
                try runCSVMapping(zipFileURL: mappingZIPFileURL, bootstrap: bootstrap)
            }
        }

        func loadBootstrap() throws -> Bootstrap {
            let entrypointURL = try TaxonomyProbe.urlFromStringOrPath(config.entrypoint)
            let entrypointBasename = entrypointURL.lastPathComponent

            let entrypointData = try TaxonomyProbe.fetchData(from: entrypointURL)
            let entrypointParser = EntrypointParser()
            let refs = try entrypointParser.parse(data: entrypointData)

            guard let chosenPresentationRef = refs.presentation.first(where: { $0.href.contains(config.wantedPresentation) }) else {
                throw Error.missingPresentation(config.wantedPresentation)
            }

            let presentationURL = try TaxonomyProbe.resolveURL(chosenPresentationRef.href, relativeTo: entrypointURL)
            let presentationData = try TaxonomyProbe.fetchData(from: presentationURL)
            let presentationParser = PresentationParser()
            let links = try presentationParser.parse(data: presentationData)

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
                presentationURL: presentationURL,
                links: links,
                labelsByConcept: labelsByConcept
            )
        }

        func runPackageProbe(zipFileURL: URL) throws {
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
                patterns: config.probePatterns,
                maxFilesToScan: config.maxFilesToScan,
                maxHits: config.maxHits
            )
        }

        func runCSVMapping(
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

            for link in bootstrap.links {
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
