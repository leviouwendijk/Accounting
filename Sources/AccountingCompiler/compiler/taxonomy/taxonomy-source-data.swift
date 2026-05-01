import Accounting
import Foundation

public enum TaxonomyLinkbaseKind: String, Sendable {
    case presentation
    case label
    case definition
    case table
    case mapping
    case other
}

public struct TaxonomyLinkbaseRule: Sendable {
    public let kind: TaxonomyLinkbaseKind
    public let roleContainsAny: [String]
    public let hrefContainsAny: [String]
    public let hrefSuffixes: [String]

    public init(
        kind: TaxonomyLinkbaseKind,
        roleContainsAny: [String] = [],
        hrefContainsAny: [String] = [],
        hrefSuffixes: [String] = []
    ) {
        self.kind = kind
        self.roleContainsAny = roleContainsAny
        self.hrefContainsAny = hrefContainsAny
        self.hrefSuffixes = hrefSuffixes
    }

    public func matches(href rawHref: String, role rawRole: String) -> Bool {
        let href = rawHref.lowercased()
        let role = rawRole.lowercased()

        if roleContainsAny.contains(where: { role.contains($0.lowercased()) }) {
            return true
        }

        if hrefContainsAny.contains(where: { href.contains($0.lowercased()) }) {
            return true
        }

        if hrefSuffixes.contains(where: { href.hasSuffix($0.lowercased()) }) {
            return true
        }

        return false
    }
}

public struct TaxonomyZIPPathBonusRule: Sendable {
    public let needle: String
    public let score: Int

    public init(
        needle: String,
        score: Int
    ) {
        self.needle = needle
        self.score = score
    }
}

public struct TaxonomyDimensionPresentationRule: Sendable {
    public let qname: String
    public let hideDimension: Bool
    public let hiddenMembers: Set<String>
    public let memberAliases: [String: String]
    public let hideWhenMemberNil: Bool
    public let nilAlias: String?
    public let fallbackAliasPrefix: String?

    public init(
        qname: String,
        hideDimension: Bool = false,
        hiddenMembers: Set<String> = [],
        memberAliases: [String: String] = [:],
        hideWhenMemberNil: Bool = false,
        nilAlias: String? = nil,
        fallbackAliasPrefix: String? = nil
    ) {
        self.qname = qname
        self.hideDimension = hideDimension
        self.hiddenMembers = hiddenMembers
        self.memberAliases = memberAliases
        self.hideWhenMemberNil = hideWhenMemberNil
        self.nilAlias = nilAlias
        self.fallbackAliasPrefix = fallbackAliasPrefix
    }
}

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

    public let linkbaseRules: [TaxonomyLinkbaseRule]
    public let mappingEntrypointPrefixes: [String]
    public let mappingEntrypointDirectories: [String]
    public let zipPathBonusRules: [TaxonomyZIPPathBonusRule]
    public let csvPriorityKeywords: [String]
    public let presentationDimensionRules: [TaxonomyDimensionPresentationRule]

    public let maxPresentationDimensionSummaryCount: Int

    public init(
        name: String,
        entrypoint: String,
        wantedPresentations: [String],
        mappingZIP: String,
        probeKeywords: [String],
        probePatterns: [String],
        labelHrefs: [String] = [],
        linkbaseRules: [TaxonomyLinkbaseRule]? = nil,
        mappingEntrypointPrefixes: [String]? = nil,
        mappingEntrypointDirectories: [String]? = nil,
        zipPathBonusRules: [TaxonomyZIPPathBonusRule] = [],
        csvPriorityKeywords: [String] = [],
        presentationDimensionRules: [TaxonomyDimensionPresentationRule]? = nil,
        maxPresentationDimensionSummaryCount: Int = 6
    ) {
        self.name = name
        self.entrypoint = entrypoint
        self.wantedPresentations = wantedPresentations
        self.mappingZIP = mappingZIP
        self.probeKeywords = probeKeywords
        self.probePatterns = probePatterns
        self.labelHrefs = labelHrefs

        self.linkbaseRules = linkbaseRules ?? Self.defaultLinkbaseRules
        self.mappingEntrypointPrefixes = mappingEntrypointPrefixes ?? ["rgs-to-"]
        self.mappingEntrypointDirectories = mappingEntrypointDirectories ?? ["entrypoints"]
        self.zipPathBonusRules = zipPathBonusRules
        self.csvPriorityKeywords = csvPriorityKeywords
        self.presentationDimensionRules =
            presentationDimensionRules ?? Self.defaultPresentationDimensionRules
        
        self.maxPresentationDimensionSummaryCount = maxPresentationDimensionSummaryCount
    }

    public func applying(overrides: TaxonomySourceOverrides) -> TaxonomySourceData {
        .init(
            name: name,
            entrypoint: overrides.entrypoint ?? entrypoint,
            wantedPresentations: overrides.wantedPresentations ?? wantedPresentations,
            mappingZIP: overrides.mappingZIP ?? mappingZIP,
            probeKeywords: overrides.probeKeywords ?? probeKeywords,
            probePatterns: overrides.probePatterns ?? probePatterns,
            labelHrefs: overrides.labelHrefs ?? labelHrefs,
            linkbaseRules: linkbaseRules,
            mappingEntrypointPrefixes: mappingEntrypointPrefixes,
            mappingEntrypointDirectories: mappingEntrypointDirectories,
            zipPathBonusRules: zipPathBonusRules,
            csvPriorityKeywords: csvPriorityKeywords,
            presentationDimensionRules: presentationDimensionRules,
            maxPresentationDimensionSummaryCount: maxPresentationDimensionSummaryCount
        )
    }

    public func classifyLinkbase(
        href: String,
        role: String
    ) -> TaxonomyLinkbaseKind {
        Self.classifyLinkbase(
            href: href,
            role: role,
            using: linkbaseRules
        )
    }

    public static func classifyLinkbaseDefault(
        href: String,
        role: String
    ) -> TaxonomyLinkbaseKind {
        classifyLinkbase(
            href: href,
            role: role,
            using: defaultLinkbaseRules
        )
    }

    private static func classifyLinkbase(
        href: String,
        role: String,
        using rules: [TaxonomyLinkbaseRule]
    ) -> TaxonomyLinkbaseKind {
        for rule in rules {
            if rule.matches(href: href, role: role) {
                return rule.kind
            }
        }

        return .other
    }

    public func mappingEntrypointCandidates(
        for entrypointBasename: String
    ) -> [String] {
        let basename = entrypointBasename.trimmingCharacters(in: .whitespacesAndNewlines)

        var out: [String] = []
        var seen: Set<String> = []

        for directory in mappingEntrypointDirectories {
            let normalizedDirectory = directory.trimmingCharacters(
                in: CharacterSet(charactersIn: "/")
            )

            for prefix in mappingEntrypointPrefixes {
                let candidate = "/\(normalizedDirectory)/\(prefix)\(basename)"
                if seen.insert(candidate).inserted {
                    out.append(candidate)
                }
            }
        }

        if out.isEmpty {
            let fallback = "/entrypoints/rgs-to-\(basename)"
            out.append(fallback)
        }

        return out
    }

    public func summarizePresentationDimension(
        _ dimension: TaxonomyDimensionBinding
    ) -> String? {
        Self.summarizePresentationDimension(
            dimension,
            using: presentationDimensionRules
        )
    }

    public static func summarizePresentationDimensionDefault(
        _ dimension: TaxonomyDimensionBinding
    ) -> String? {
        summarizePresentationDimension(
            dimension,
            using: defaultPresentationDimensionRules
        )
    }

    private static func summarizePresentationDimension(
        _ dimension: TaxonomyDimensionBinding,
        using rules: [TaxonomyDimensionPresentationRule]
    ) -> String? {
        if let rule = rules.first(where: { $0.qname == dimension.axis }) {
            if rule.hideDimension {
                return nil
            }

            let member = dimension.member

            if !member.isEmpty {
                if rule.hiddenMembers.contains(member) {
                    return nil
                }

                if let alias = rule.memberAliases[member] {
                    return alias
                }

                if let prefix = rule.fallbackAliasPrefix {
                    return "\(prefix)=\(member)"
                }

                return "\(dimension.axis)=\(member)"
            }

            if rule.hideWhenMemberNil {
                return nil
            }

            if let alias = rule.nilAlias {
                return alias
            }

            return dimension.axis
        }

        if !dimension.member.isEmpty {
            return "\(dimension.axis)=\(dimension.member)"
        }

        return dimension.axis
    }

    public static let defaultLinkbaseRules: [TaxonomyLinkbaseRule] = [
        .init(
            kind: .presentation,
            roleContainsAny: ["presentationlinkbaseref"],
            hrefSuffixes: ["-pre.xml"]
        ),
        .init(
            kind: .label,
            roleContainsAny: ["labellinkbaseref"],
            hrefSuffixes: ["-lab.xml"]
        ),
        .init(
            kind: .definition,
            roleContainsAny: ["definitionlinkbaseref"],
            hrefSuffixes: ["-def.xml"]
        ),
        .init(
            kind: .table,
            roleContainsAny: ["tablelinkbaseref"],
            hrefSuffixes: ["-tab.xml"]
        ),
        .init(
            kind: .mapping,
            roleContainsAny: ["mapping"],
            hrefContainsAny: ["/mapping/", "/map/", "map-"]
        )
    ]

    public static let defaultPresentationDimensionRules: [TaxonomyDimensionPresentationRule] = [
        .init(
            qname: "bd-dim-dim:CompanySerialNumberDimension",
            hideDimension: true
        ),
        .init(
            qname: "bd-dim-dim:PartyDimension",
            hiddenMembers: ["bd-dim-mem:Company"],
            memberAliases: [
                "bd-dim-mem:Declarant": "declarant"
            ],
            nilAlias: "party",
            fallbackAliasPrefix: "party"
        ),
        .init(
            qname: "bd-dim-dim:TimeDimension",
            memberAliases: [
                "bd-dim-mem:Begin": "begin",
                "bd-dim-mem:End": "end"
            ],
            nilAlias: "time",
            fallbackAliasPrefix: "time"
        )
    ]
}

public enum TaxonomySourceProfile: String, CaseIterable, Sendable {
    case bd_ihz_2025
    case bd_vpb_2025

    public var data: TaxonomySourceData {
        switch self {
        case .bd_ihz_2025:
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
                ],
                zipPathBonusRules: [
                    .init(needle: "rgs-to-bd-rpt-ihz-aangifte-2025", score: 50),
                    .init(needle: "map-bd-ihz", score: 40)
                ],
                csvPriorityKeywords: [
                    "ihz",
                    "aangifte"
                ]
            )

        case .bd_vpb_2025:
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
                ],
                zipPathBonusRules: [
                    .init(needle: "rgs-to-bd-rpt-vpb-aangifte-2025", score: 50),
                    .init(needle: "map-bd-vpb", score: 40)
                ],
                csvPriorityKeywords: [
                    "vpb",
                    "aangifte"
                ]
            )
        }
    }
}

