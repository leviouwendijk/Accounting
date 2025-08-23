import Foundation

public enum AccountStoreLoader {
    public static func load(from project: EntryCompilerProject, base: [RGSAccount]) throws -> AccountStore {
        var builder = AccountStoreBuilder()
        try builder.addBase(base)
        return try builder.freeze()
    }

    public static func load(fromBase base: [RGSAccount]) throws -> AccountStore {
        var b = AccountStoreBuilder()
        try b.addBase(base)
        return try b.freeze()
    }
}
