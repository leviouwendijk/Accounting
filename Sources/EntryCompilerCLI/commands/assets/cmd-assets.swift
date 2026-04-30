import Arguments

enum AssetsCommand: ArgumentCommand {
    static let name = "assets"
    static let defaultChild = AssetsOverviewCommand.self

    static let children: [ArgumentCommandType] = [
        AssetsOverviewCommand.self,
        AssetsAcquiredCommand.self,
        AssetsValidateCommand.self,
        AssetsSharesCommand.self,
    ]
}
