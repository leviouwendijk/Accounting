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
    public let selectedEntryPath: String
    public let linkbase: TaxonomyGenericLinkbase

    public init(
        rankedCandidates: [String],
        selectedEntryPath: String,
        linkbase: TaxonomyGenericLinkbase
    ) {
        self.rankedCandidates = rankedCandidates
        self.selectedEntryPath = selectedEntryPath
        self.linkbase = linkbase
    }
}
