import Arguments

@main
enum EntryCompilerCLICommand: ArgumentCommand {
    static let name = "ec"
    static let defaultChild = CompileCommand.self

    static let children: [ArgumentCommandType] = [
        CompileCommand.self,
        DepreciationCommand.self,
        IDCommand.self,
        RGSHierarchyCommand.self,
        EquityCommand.self,
        PeriodCommand.self,
        VATCommand.self,
        TaxonomyProbeCommand.self,
        KIACommand.self,
        DocumentCommand.self,
        AssetsCommand.self,
        SourceCommand.self,
        MetaCommand.self,
        CostCommand.self,
    ]
}
