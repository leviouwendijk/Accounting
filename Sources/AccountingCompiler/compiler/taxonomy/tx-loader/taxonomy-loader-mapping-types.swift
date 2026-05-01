import Accounting
import Foundation

public struct LoadedTaxonomyCSVMapping: Sendable {
    public let entryPath: String
    public let mappingFile: TaxonomyCSVMappingFile

    public init(
        entryPath: String,
        mappingFile: TaxonomyCSVMappingFile
    ) {
        self.entryPath = entryPath
        self.mappingFile = mappingFile
    }
}

public struct LoadedTaxonomyGenericMapping: Sendable {
    public let rankedCandidates: [String]
    public let selectedEntrypointPath: String
    public let mappingEntryPaths: [String]
    public let resolvedMappings: [TaxonomyResolvedMapping]
    public let diagnostics: [String: TaxonomyMappingResolutionDiagnostics]

    public init(
        rankedCandidates: [String],
        selectedEntrypointPath: String,
        mappingEntryPaths: [String],
        resolvedMappings: [TaxonomyResolvedMapping],
        diagnostics: [String: TaxonomyMappingResolutionDiagnostics]
    ) {
        self.rankedCandidates = rankedCandidates
        self.selectedEntrypointPath = selectedEntrypointPath
        self.mappingEntryPaths = mappingEntryPaths
        self.resolvedMappings = resolvedMappings
        self.diagnostics = diagnostics
    }
}
