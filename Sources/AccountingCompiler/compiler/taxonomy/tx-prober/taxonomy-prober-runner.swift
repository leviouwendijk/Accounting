import Accounting
import Foundation

public struct TaxonomyProberRunner: Sendable {
    public let config: TaxonomyProbeConfig

    public init(
        config: TaxonomyProbeConfig = .init()
    ) {
        self.config = config
    }

    public func run() throws {
        let bootstrap = try TaxonomyLoader.load(
            config: .init(
                source: config.source,
                wantedPresentations: config.wantedPresentations,
                labelHrefs: config.labelHrefs
            )
        )

        print("entrypoint: \(bootstrap.entrypointURL.absoluteString)")
        print("")
        print("discovery:")
        print("  presentation refs: \(bootstrap.refs.presentation.count)")
        print("  label refs: \(bootstrap.refs.labels.count)")
        print("  definition refs: \(bootstrap.refs.definitions.count)")
        print("  table refs: \(bootstrap.refs.tables.count)")
        print("  mapping refs: \(bootstrap.refs.mappings.count)")
        print("  other refs: \(bootstrap.refs.other.count)")
        print("")
        print("selected presentations: \(bootstrap.selectedPresentationURLs.count)")
        for url in bootstrap.selectedPresentationURLs {
            print("  \(url.absoluteString)")
        }
        print("")
        print("presentationLink count: \(bootstrap.selectedPresentationLinks.count)")
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

        let mappingZIPURL = try TaxonomyShared.urlFromStringOrPath(config.mappingZIP)
        print("fetching mapping zip: \(mappingZIPURL.absoluteString)")
        let mappingZIPData = try TaxonomyLoader.fetchData(from: mappingZIPURL)
        print("mapping zip bytes: \(mappingZIPData.count)")

        let mappingZIPFileURL = try TaxonomyLoader.writeTempFile(
            data: mappingZIPData,
            suffix: "zip"
        )
        defer {
            try? FileManager.default.removeItem(at: mappingZIPFileURL)
        }

        print("mapping temp file: \(mappingZIPFileURL.path)")
        print("")

        switch config.mode {
        case .probePackage:
            try runPackageProbe(
                zipFileURL: mappingZIPFileURL
            )

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
}
