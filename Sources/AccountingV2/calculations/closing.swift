import Foundation

/// A deterministic assessment of possible period-closing effects.
/// Evaluation never records or applies the proposed effects.
public struct Closing: Calculation {
    public struct Input: Sendable {
        public let period: Period
        public let equityAccount: Account.Reference

        public init(period: Period, equityAccount: Account.Reference) {
            self.period = period
            self.equityAccount = equityAccount
        }
    }

    public enum Error: Swift.Error, Equatable, Sendable {
        case unknownEquityAccount(Account.Reference)
        case nonPostableEquityAccount(Account.Reference)
        case nonEquityAccount(Account.Reference)
        case unknownSourceAccount(Account.Reference)
        case uncategorizedSourceAccount(Account.Reference)
    }

    /// Signed movements by temporary-account category.
    /// Debit is positive, credit negative, including on revenue accounts.
    public struct Assessment: Sendable {
        public let revenue: Decimal
        public let expenses: Decimal
        public let dividends: Decimal

        /// Positive denotes profit; negative denotes loss.
        public var netIncome: Decimal {
            -(revenue + expenses)
        }

        /// Signed amount of the proposed equity contribution.
        /// Profits normally produce a negative (credit) contribution.
        public var equityContribution: Decimal {
            revenue + expenses + dividends
        }

        fileprivate init(revenue: Decimal, expenses: Decimal, dividends: Decimal) {
            self.revenue = revenue
            self.expenses = expenses
            self.dividends = dividends
        }
    }

    /// A proposal is not evidence of an applied or recorded closing entry.
    public enum Decision: Equatable, Sendable {
        case notNeeded
        case proposed
    }

    /// A derived contribution that may be used by later projections.
    /// This is not a journal line or an authoritative ledger posting.
    public struct Effect: Sendable {
        public enum Kind: Equatable, Sendable {
            case clearTemporary
            case transferToEquity
        }

        public let kind: Kind
        public let account: Account.Reference
        public let entity: Entity.Reference
        public let signedAmount: Decimal
        public let sources: [Posting.Source]

        fileprivate init(
            kind: Kind,
            account: Account.Reference,
            entity: Entity.Reference,
            signedAmount: Decimal,
            sources: [Posting.Source]
        ) {
            self.kind = kind
            self.account = account
            self.entity = entity
            self.signedAmount = signedAmount
            self.sources = sources
        }
    }

    /// Full assessment, proposed decision and traceable derived effects.
    /// The original Period retains the authoritative journal and ledger.
    public struct Audit: Sendable {
        public let period: Period
        public let equityAccount: Account.Reference
        public let assessment: Assessment
        public let decision: Decision
        public let effects: [Effect]

        fileprivate init(
            period: Period,
            equityAccount: Account.Reference,
            assessment: Assessment,
            decision: Decision,
            effects: [Effect]
        ) {
            self.period = period
            self.equityAccount = equityAccount
            self.assessment = assessment
            self.decision = decision
            self.effects = effects
        }

        /// All proposed effects must sum to zero under signed accounting.
        public var effectBalance: Decimal {
            effects.reduce(Decimal.zero) { $0 + $1.signedAmount }
        }
    }

    private struct Key: Hashable {
        let account: Account.Reference
        let entity: Entity.Reference
    }

    public init() {}

    public func evaluate(_ input: Input) throws(Error) -> Audit {
        let chart = input.period.ledger.journal.chart

        guard let equity = chart.account(input.equityAccount) else {
            throw .unknownEquityAccount(input.equityAccount)
        }
        guard equity.postable else {
            throw .nonPostableEquityAccount(input.equityAccount)
        }
        guard equity.category == .equity else {
            throw .nonEquityAccount(input.equityAccount)
        }

        var revenue = Decimal.zero
        var expenses = Decimal.zero
        var dividends = Decimal.zero

        var accountOrder: [Key] = []
        var signedByAccount: [Key: Decimal] = [:]
        var sourcesByAccount: [Key: [Posting.Source]] = [:]

        var entityOrder: [Entity.Reference] = []
        var signedByEntity: [Entity.Reference: Decimal] = [:]
        var sourcesByEntity: [Entity.Reference: [Posting.Source]] = [:]

        for posting in input.period.movements.postings {
            guard let account = chart.account(posting.account) else {
                throw .unknownSourceAccount(posting.account)
            }
            guard let category = account.category else {
                throw .uncategorizedSourceAccount(posting.account)
            }

            let signed = posting.signedAmount
            switch category {
            case .revenue:
                revenue += signed
            case .expenses:
                expenses += signed
            case .dividends:
                dividends += signed
            case .assets, .liabilities, .equity:
                continue
            }

            let key = Key(account: posting.account, entity: posting.entity)
            if signedByAccount[key] == nil {
                accountOrder.append(key)
            }
            signedByAccount[key, default: 0] += signed
            sourcesByAccount[key, default: []].append(posting.source)

            if signedByEntity[posting.entity] == nil {
                entityOrder.append(posting.entity)
            }
            signedByEntity[posting.entity, default: 0] += signed
            sourcesByEntity[posting.entity, default: []].append(posting.source)
        }

        var effects: [Effect] = []
        for key in accountOrder {
            let signed = signedByAccount[key] ?? 0
            guard signed != 0 else { continue }

            effects.append(Effect(
                kind: .clearTemporary,
                account: key.account,
                entity: key.entity,
                signedAmount: -signed,
                sources: sourcesByAccount[key] ?? []
            ))
        }

        for entity in entityOrder {
            let signed = signedByEntity[entity] ?? 0
            guard signed != 0 else { continue }

            effects.append(Effect(
                kind: .transferToEquity,
                account: input.equityAccount,
                entity: entity,
                signedAmount: signed,
                sources: sourcesByEntity[entity] ?? []
            ))
        }

        return Audit(
            period: input.period,
            equityAccount: input.equityAccount,
            assessment: Assessment(
                revenue: revenue,
                expenses: expenses,
                dividends: dividends
            ),
            decision: effects.isEmpty ? .notNeeded : .proposed,
            effects: effects
        )
    }
}
