import Foundation

public extension Chart {
    /// Semantic destinations independent of native account-code spelling.
    enum Role: Hashable, Sendable {
        case equity_opening
        case named(String)

        fileprivate var valid: Bool {
            switch self {
            case .equity_opening:
                return true
            case .named(let name):
                return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }

    /// Required behavior declaration for an account chart.
    struct Behavior: Sendable {
        public enum Carryforward: Sendable {
            /// Every account retains its own identity.
            case identity

            /// Explicit mappings, including an explicit unmatched policy.
            case mapped(rules: [Rule], otherwise: Otherwise)
        }

        public enum Otherwise: Sendable {
            case identity
            case reject
        }

        public struct Rule: Sendable {
            public enum Source: Sendable {
                case account(Account.Reference)

                /// Includes the root and its descendants. Each excluded
                /// account excludes its complete subtree.
                case subtree(root: Account.Reference, excluding: [Account.Reference])
            }

            public enum Destination: Sendable {
                case account(Account.Reference)
                case role(Role)
                case same_account
            }

            public let source: Source
            public let destination: Destination

            public init(source: Source, destination: Destination) {
                self.source = source
                self.destination = destination
            }
        }

        public let carryforward: Carryforward
        public let roles: [Role: Account.Reference]

        public init(
            carryforward: Carryforward,
            roles: [Role: Account.Reference] = [:]
        ) {
            self.carryforward = carryforward
            self.roles = roles
        }
    }
}

extension Chart {
    /// Resolve declarative routing exactly once against the validated forest.
    /// An absent result is meaningful only for an explicitly rejecting policy.
    static func resolveCarryforward(
        _ behavior: Behavior,
        accounts: [Account],
        parents: [Account.Reference: Account.Reference]
    ) throws(Error) -> [Account.Reference: Account.Reference] {
        let known = Set(accounts.map(\.reference))

        for (role, destination) in behavior.roles {
            guard role.valid else { throw .invalidRoleName }
            guard known.contains(destination) else {
                throw .unknownRoleAccount(role: role, account: destination)
            }
        }

        switch behavior.carryforward {
        case .identity:
            return Dictionary(uniqueKeysWithValues: accounts.map {
                ($0.reference, $0.reference)
            })

        case .mapped(let rules, let otherwise):
            var resolved: [Account.Reference: Account.Reference] = [:]

            for rule in rules {
                let sources: [Account.Reference]
                switch rule.source {
                case .account(let source):
                    guard known.contains(source) else {
                        throw .unknownRouteSource(source)
                    }
                    sources = [source]

                case .subtree(let root, let exclusions):
                    guard known.contains(root) else {
                        throw .unknownRouteSource(root)
                    }
                    for exclusion in exclusions {
                        guard known.contains(exclusion),
                              isWithin(exclusion, root: root, parents: parents)
                        else {
                            throw .invalidRouteExclusion(
                                root: root,
                                excluded: exclusion
                            )
                        }
                    }
                    sources = accounts.map(\.reference).filter { source in
                        isWithin(source, root: root, parents: parents)
                            && !exclusions.contains {
                                isWithin(source, root: $0, parents: parents)
                            }
                    }
                }

                let fixedDestination: Account.Reference?
                switch rule.destination {
                case .same_account:
                    fixedDestination = nil

                case .account(let destination):
                    guard known.contains(destination) else {
                        throw .unknownRouteDestination(destination)
                    }
                    fixedDestination = destination

                case .role(let role):
                    guard role.valid else { throw .invalidRoleName }
                    guard let destination = behavior.roles[role] else {
                        throw .unboundRole(role)
                    }
                    fixedDestination = destination
                }

                for source in sources {
                    guard resolved[source] == nil else {
                        throw .overlappingRoute(source)
                    }
                    resolved[source] = fixedDestination ?? source
                }
            }

            if case .identity = otherwise {
                for account in accounts where resolved[account.reference] == nil {
                    resolved[account.reference] = account.reference
                }
            }

            return resolved
        }
    }

    private static func isWithin(
        _ account: Account.Reference,
        root: Account.Reference,
        parents: [Account.Reference: Account.Reference]
    ) -> Bool {
        var cursor: Account.Reference? = account
        while let current = cursor {
            if current == root { return true }
            cursor = parents[current]
        }
        return false
    }
}
