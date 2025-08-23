import Foundation

public enum AccountStoreLoader {
    public static func load(from project: EntryCompilerProject, base: [RGSAccount]) throws -> AccountStore {
        var builder = AccountStoreBuilder()
        try builder.addBase(base)
        return try builder.freeze()
    }
}
