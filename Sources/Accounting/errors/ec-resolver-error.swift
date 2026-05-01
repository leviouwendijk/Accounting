import Foundation

public enum EntryCompilerResolverError: Error, LocalizedError, CustomStringConvertible {
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
            var lines: [String] = [
                "Incompatible entity/account intersection",
                "    entity: \(entity)",
                "    account: \(account)"
            ]

            if !reason.isEmpty {
                lines.append("    reason: \(reason)")
            }

            if let at {
                lines.append("    at: \(at)")
            }

            return lines.joined(separator: "\n")
        }
    }

    public var description: String {
        errorDescription ?? String(reflecting: self)
    }
}
