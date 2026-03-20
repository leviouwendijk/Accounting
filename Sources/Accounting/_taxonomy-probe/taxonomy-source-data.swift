import Foundation

public struct TaxonomySourceOverrides: Sendable {
    public let entrypoint: String?
    public let wantedPresentations: [String]?
    public let mappingZIP: String?
    public let probeKeywords: [String]?
    public let probePatterns: [String]?
    public let labelHrefs: [String]?

    public init(
        entrypoint: String? = nil,
        wantedPresentations: [String]? = nil,
        mappingZIP: String? = nil,
        probeKeywords: [String]? = nil,
        probePatterns: [String]? = nil,
        labelHrefs: [String]? = nil
    ) {
        self.entrypoint = entrypoint
        self.wantedPresentations = wantedPresentations
        self.mappingZIP = mappingZIP
        self.probeKeywords = probeKeywords
        self.probePatterns = probePatterns
        self.labelHrefs = labelHrefs
    }
}

public struct TaxonomySourceData: Sendable {
    public let name: String
    public let entrypoint: String
    public let wantedPresentations: [String]
    public let mappingZIP: String
    public let probeKeywords: [String]
    public let probePatterns: [String]
    public let labelHrefs: [String]

    public init(
        name: String,
        entrypoint: String,
        wantedPresentations: [String],
        mappingZIP: String,
        probeKeywords: [String],
        probePatterns: [String],
        labelHrefs: [String] = []
    ) {
        self.name = name
        self.entrypoint = entrypoint
        self.wantedPresentations = wantedPresentations
        self.mappingZIP = mappingZIP
        self.probeKeywords = probeKeywords
        self.probePatterns = probePatterns
        self.labelHrefs = labelHrefs
    }

    public func applying(overrides: TaxonomySourceOverrides) -> TaxonomySourceData {
        .init(
            name: name,
            entrypoint: overrides.entrypoint ?? entrypoint,
            wantedPresentations: overrides.wantedPresentations ?? wantedPresentations,
            mappingZIP: overrides.mappingZIP ?? mappingZIP,
            probeKeywords: overrides.probeKeywords ?? probeKeywords,
            probePatterns: overrides.probePatterns ?? probePatterns,
            labelHrefs: overrides.labelHrefs ?? labelHrefs
        )
    }
}

public enum TaxonomySourceProfile: String, CaseIterable, Sendable {
    case bdIhz2025
    case bdVpb2025

    public var data: TaxonomySourceData {
        switch self {
        case .bdIhz2025:
            return .init(
                name: "Belastingdienst IHZ 2025",
                entrypoint: "https://www.nltaxonomie.nl/nt20/bd/20251210/entrypoints/bd-rpt-ihz-aangifte-2025.xsd",
                wantedPresentations: [
                    "winst-resultatenrekening-pre.xml",
                    "winst-activa-pre.xml",
                    "winst-passiva-pre.xml",
                    "winst-berekening-pre.xml"
                ],
                mappingZIP: "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip",
                probeKeywords: [
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
                probePatterns: [
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
                    "roleRef",
                    "arcroleRef",
                    "presentationLink",
                    "definitionLink",
                    "tableLink",
                    "labelLink",
                    "datapoint",
                    "explicitDimension",
                    "primary",
                    "xlink:role",
                    "xlink:arcrole",
                    "rgs-i_",
                    "rgs-k_",
                    "bd-i_",
                    "bd-t_",
                    "bd-abstr_",
                    "bd-dim-dim:",
                    "bd-dim-mem:"
                ],
                labelHrefs: [
                    "../dictionary/bd-data-lab-nl.xml",
                    "../dictionary/bd-tuples-lab-nl.xml"
                ]
            )

        case .bdVpb2025:
            return .init(
                name: "Belastingdienst VPB 2025",
                entrypoint: "https://www.nltaxonomie.nl/nt20/bd/20251210/entrypoints/bd-rpt-vpb-aangifte-2025.xsd",
                wantedPresentations: [],
                mappingZIP: "https://www.referentiegrootboekschema.nl/sites/default/files/kennisbank/NT20_RGS_20251210.zip",
                probeKeywords: [
                    "bd",
                    "vpb",
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
                probePatterns: [
                    "rgs-to-bd-rpt-vpb-aangifte-2025",
                    "bd-rpt-vpb-aangifte-2025",
                    "bd-vpb-aangifte",
                    "map-bd-vpb",
                    "mapping/",
                    "entrypoints/",
                    "presentation/",
                    "definition/",
                    "table/",
                    "dictionary/",
                    "linkbaseRef",
                    "roleRef",
                    "arcroleRef",
                    "presentationLink",
                    "definitionLink",
                    "tableLink",
                    "labelLink",
                    "datapoint",
                    "explicitDimension",
                    "primary",
                    "xlink:role",
                    "xlink:arcrole",
                    "rgs-i_",
                    "rgs-k_",
                    "bd-i_",
                    "bd-t_",
                    "bd-abstr_",
                    "bd-dim-dim:",
                    "bd-dim-mem:"
                ],
                labelHrefs: [
                    "../dictionary/bd-data-lab-nl.xml",
                    "../dictionary/bd-tuples-lab-nl.xml"
                ]
            )
        }
    }
}
