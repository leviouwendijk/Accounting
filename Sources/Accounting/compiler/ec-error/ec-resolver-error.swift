import Foundation

public enum EntryCompilerResolverError: Error, LocalizedError {
    case notImplemented

    case incompatibleEntityAccount(
        entity: String,
        account: String,
        reason: String,
        at: SourceLocation?
    )

    public var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Resolver operation is not implemented."

        case .incompatibleEntityAccount(
            let entity,
            let account,
            let reason,
            let at
        ):
            var s = "Invalid entity/account intersection: entity '\(entity)' cannot be used with account '\(account)'"
            if !reason.isEmpty {
                s += " (\(reason))"
            }
            if let at {
                s += " @ \(at)"
            }
            return s
        }
    }
}
