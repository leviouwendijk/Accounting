import Foundation

public enum TaxonomyProbe {}
public enum TaxonomyProber {}
public enum TaxonomyParser {}
public enum TaxonomyShared {}
public enum TaxonomyLoader {}
public enum TaxonomyProjection {}
public enum TaxonomyTester {}

public enum TaxonomyProbeMode: String, Sendable, CaseIterable {
    case probePackage
    case inspectGenericMapping
    case csvMapping
}

public enum TaxonomyProbeBalanceInputMode: String, Sendable, CaseIterable {
    case demo
    case project
}

public struct TaxonomyProbeConfig: Sendable {
    public let source: TaxonomySourceData
    public let mode: TaxonomyProbeMode
    public let maxFilesToScan: Int
    public let maxHits: Int
    public let chartFile: String?
    public let balanceInput: TaxonomyProbeBalanceInputMode
    public let projectRoot: String?
    public let demoRGSBalances: [String: Decimal]

    public init(
        source: TaxonomySourceData = TaxonomySourceProfile.bd_ihz_2025.data,
        mode: TaxonomyProbeMode = .probePackage,
        maxFilesToScan: Int = 400,
        maxHits: Int = 80,
        chartFile: String? = nil,
        balanceInput: TaxonomyProbeBalanceInputMode = .demo,
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
        self.source = source
        self.mode = mode
        self.maxFilesToScan = maxFilesToScan
        self.maxHits = maxHits
        self.chartFile = chartFile
        self.balanceInput = balanceInput
        self.projectRoot = projectRoot
        self.demoRGSBalances = demoRGSBalances
    }

    public var entrypoint: String {
        source.entrypoint
    }

    public var wantedPresentations: [String] {
        source.wantedPresentations
    }

    public var mappingZIP: String {
        source.mappingZIP
    }

    public var probeKeywords: [String] {
        source.probeKeywords
    }

    public var probePatterns: [String] {
        source.probePatterns
    }

    public var labelHrefs: [String] {
        source.labelHrefs
    }
}

public enum TaxonomyProbeError: Swift.Error, CustomStringConvertible, Sendable {
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
            return "inspectGenericMapping requires a compiled chart JSON via chartFile / --chart"
        }
    }
}
