import Foundation
import Primitives

/// A complete, validated account forest. Only declared roots may be parentless.
/// The tree and indexes are derived from the same authoritative parent edges.
public struct Chart: Invariant, Sendable {
    public struct Raw: Sendable {
        public let accounts: [Account]
        public let roots: [Account.Reference]
        public let parents: [Account.Reference: Account.Reference]
        public let behavior: Behavior

        public init(
            accounts: [Account],
            roots: [Account.Reference],
            parents: [Account.Reference: Account.Reference],
            behavior: Behavior
        ) {
            self.accounts = accounts
            self.roots = roots
            self.parents = parents
            self.behavior = behavior
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case emptyRoots
        case duplicateAccount(Account.Reference)
        case duplicateRoot(Account.Reference)
        case unknownRoot(Account.Reference)
        case unknownChild(Account.Reference)
        case unknownParent(child: Account.Reference, parent: Account.Reference)
        case rootHasParent(Account.Reference)
        case missingParent(Account.Reference)
        case missingRoot(Account.Reference)
        case cycle(Account.Reference)
        case invalidRoleName
        case unknownRoleAccount(role: Role, account: Account.Reference)
        case unknownRouteSource(Account.Reference)
        case unknownRouteDestination(Account.Reference)
        case invalidRouteExclusion(root: Account.Reference, excluded: Account.Reference)
        case unboundRole(Role)
        case overlappingRoute(Account.Reference)
    }

    public let hierarchy: Tree<Account>
    public let behavior: Behavior
    private let accountsByReference: [Account.Reference: Account]
    private let parentsByReference: [Account.Reference: Account.Reference]
    private let carryforwardDestinations: [Account.Reference: Account.Reference]

    public init(_ raw: Raw) throws(Error) {
        guard !raw.roots.isEmpty else { throw .emptyRoots }

        var accounts: [Account.Reference: Account] = [:]
        accounts.reserveCapacity(raw.accounts.count)
        for account in raw.accounts {
            guard accounts.updateValue(account, forKey: account.reference) == nil else {
                throw .duplicateAccount(account.reference)
            }
        }

        var roots: Set<Account.Reference> = []
        for reference in raw.roots {
            guard accounts[reference] != nil else { throw .unknownRoot(reference) }
            guard roots.insert(reference).inserted else { throw .duplicateRoot(reference) }
        }

        for (child, parent) in raw.parents {
            guard accounts[child] != nil else { throw .unknownChild(child) }
            guard accounts[parent] != nil else {
                throw .unknownParent(child: child, parent: parent)
            }
            guard !roots.contains(child) else { throw .rootHasParent(child) }
        }

        for account in raw.accounts {
            let reference = account.reference
            guard roots.contains(reference) || raw.parents[reference] != nil else {
                throw .missingParent(reference)
            }

            var seen: Set<Account.Reference> = []
            var cursor = reference
            while let parent = raw.parents[cursor] {
                guard seen.insert(cursor).inserted else { throw .cycle(cursor) }
                cursor = parent
            }
            guard roots.contains(cursor) else { throw .missingRoot(reference) }
        }

        var children: [Account.Reference: [Account.Reference]] = [:]
        for account in raw.accounts {
            let child = account.reference
            if let parent = raw.parents[child] {
                children[parent, default: []].append(child)
            }
        }

        func makeNode(_ reference: Account.Reference) throws(Error) -> Tree<Account>.Node {
            guard let account = accounts[reference] else { throw .unknownRoot(reference) }
            var descendants: [Tree<Account>.Node] = []
            for child in children[reference] ?? [] {
                descendants.append(try makeNode(child))
            }
            return Tree<Account>.Node(account, children: descendants)
        }

        var rootNodes: [Tree<Account>.Node] = []
        for reference in raw.roots {
            rootNodes.append(try makeNode(reference))
        }

        let destinations = try Self.resolveCarryforward(
            raw.behavior,
            accounts: raw.accounts,
            parents: raw.parents
        )

        self.hierarchy = Tree(roots: rootNodes)
        self.behavior = raw.behavior
        self.accountsByReference = accounts
        self.parentsByReference = raw.parents
        self.carryforwardDestinations = destinations
    }

    public var count: Int { accountsByReference.count }

    /// The validated destination for this account's carryforward contribution.
    /// Returns nil for unknown sources or sources explicitly rejected by policy.
    public func carryforwardDestination(
        for source: Account.Reference
    ) -> Account.Reference? {
        carryforwardDestinations[source]
    }

    public func account(_ reference: Account.Reference) -> Account? {
        accountsByReference[reference]
    }

    public func parent(of reference: Account.Reference) -> Account.Reference? {
        parentsByReference[reference]
    }

    public func isPostable(_ reference: Account.Reference) -> Bool? {
        account(reference)?.postable
    }

    /// Operational equivalence required before continuing a financial state.
    /// Chart migrations and effective-dated policy changes require an explicit
    /// adapter rather than silent reuse of an earlier hierarchy.
    func isCompatibleForContinuity(with other: Chart) -> Bool {
        guard accountsByReference.count == other.accountsByReference.count,
              parentsByReference == other.parentsByReference,
              carryforwardDestinations == other.carryforwardDestinations,
              behavior.roles == other.behavior.roles
        else {
            return false
        }

        for (reference, account) in accountsByReference {
            guard let counterpart = other.accountsByReference[reference],
                  account.label == counterpart.label,
                  account.category == counterpart.category,
                  account.postable == counterpart.postable
            else {
                return false
            }
        }

        return true
    }

    /// Unknown accounts return nil; declared roots return an empty list.
    public func ancestors(of reference: Account.Reference) -> [Account.Reference]? {
        guard accountsByReference[reference] != nil else { return nil }
        var result: [Account.Reference] = []
        var cursor = reference
        while let parent = parentsByReference[cursor] {
            result.append(parent)
            cursor = parent
        }
        return result
    }
}
