import Foundation
import Primitives

/// Diagnostic evidence for Accounting-owned rules. No accounting semantics leak into Primitives.
public enum AccountingInvarianceReason: InvarianceReason {
    case entry_unbalanced(debit: Decimal, credit: Decimal, delta: Decimal)
    case entry_empty
    case entry_posting_date_unresolved
    case transaction_amount_inconsistent(gross: Decimal, fee: Decimal, net: Decimal, expected_net: Decimal)
    case transaction_missing_id
    case transaction_duplicate_id(id: Int, first_index: Int, duplicate_index: Int)
    case transaction_reference_missing(Int)
    case unsupported_currency(actual: String, supported: Set<String>)
    case account_reference_missing(AccountKey)
    case entity_reference_missing(EntityKey)
    case allocation_total_mismatch(expected: Decimal, actual: Decimal)

    public var code: InvarianceCode {
        switch self {
        case .entry_unbalanced: .custom("accounting.entry.unbalanced")
        case .entry_empty: .custom("accounting.entry.empty")
        case .entry_posting_date_unresolved: .custom("accounting.entry.posting_date_unresolved")
        case .transaction_amount_inconsistent: .custom("accounting.transaction.amount_inconsistent")
        case .transaction_missing_id: .custom("accounting.transaction.missing_id")
        case .transaction_duplicate_id: .custom("accounting.transaction.duplicate_id")
        case .transaction_reference_missing: .custom("accounting.transaction.reference_missing")
        case .unsupported_currency: .custom("accounting.currency.unsupported")
        case .account_reference_missing: .custom("accounting.account.reference_missing")
        case .entity_reference_missing: .custom("accounting.entity.reference_missing")
        case .allocation_total_mismatch: .custom("accounting.allocation.total_mismatch")
        }
    }

    public var message: String {
        switch self {
        case .entry_unbalanced(_, _, let delta): "Entry imbalance: \(delta)."
        case .entry_empty: "Entry must contain posting lines."
        case .entry_posting_date_unresolved: "Posting date is not absolute."
        case .transaction_amount_inconsistent: "Transaction net is inconsistent with gross minus fee."
        case .transaction_missing_id: "Transaction ID is missing."
        case .transaction_duplicate_id(let id, _, _): "Duplicate transaction ID: \(id)."
        case .transaction_reference_missing(let id): "Unknown transaction reference: \(id)."
        case .unsupported_currency(let actual, _): "Unsupported currency: \(actual)."
        case .account_reference_missing(let key): "Unknown account: \(key.code)."
        case .entity_reference_missing: "Unknown entity reference."
        case .allocation_total_mismatch: "Allocation total does not equal the required amount."
        }
    }
}

public struct AccountingEntryInvarianceRules: Sendable {
    public init() {}

    public var nonempty: InvarianceRule<ResolvedEntry> {
        InvarianceRule { entry in
            entry.lines.isEmpty ? [
                InvarianceViolation(
                    AccountingInvarianceReason.entry_empty,
                    path: [.field("lines")]
                )
            ] : []
        }
    }

    public var balanced: InvarianceRule<ResolvedEntry> {
        InvarianceRule { entry in
            var debit: Decimal = 0
            var credit: Decimal = 0
            for line in entry.lines {
                if line.direction == .debit {
                    debit += line.amount
                } else {
                    credit += line.amount
                }
            }
            guard !debit.isNaN && !credit.isNaN else {
                return [
                    InvarianceViolation(
                        InvarianceNonfiniteNumber(actual: debit - credit),
                        path: [.field("lines")]
                    )
                ]
            }
            guard debit != credit else { return [] }
            return [
                InvarianceViolation(
                    AccountingInvarianceReason.entry_unbalanced(
                        debit: debit,
                        credit: credit,
                        delta: debit - credit
                    ),
                    path: [.field("lines")]
                )
            ]
        }
    }

    public var posting_date_resolved: InvarianceRule<ResolvedEntry> {
        InvarianceRule { entry in
            guard case .absolute = entry.date else {
                return [
                    InvarianceViolation(
                        AccountingInvarianceReason.entry_posting_date_unresolved,
                        path: [.field("date")]
                    )
                ]
            }

            return []
        }
    }
}

public extension InvarianceRule where Value == ResolvedEntry {
    static var entry: AccountingEntryInvarianceRules { .init() }
}

public struct AccountingTransactionAmountInvarianceRules: Sendable {
    public init() {}

    /// Assumes non-negative fees reduce gross: net = gross - fee.
    /// A missing net value does not assert a relationship. No mutation or derivation occurs.
    public var amounts_consistent: InvarianceRule<TransactionAmount> {
        InvarianceRule { amount in
            let fee = amount.fee ?? 0
            let expected = amount.gross - fee
            guard !amount.gross.isNaN && !fee.isNaN && !expected.isNaN else {
                return [InvarianceViolation(InvarianceNonfiniteNumber(actual: expected))]
            }
            guard let net = amount.net else { return [] }
            guard !net.isNaN else {
                return [InvarianceViolation(InvarianceNonfiniteNumber(actual: net))]
            }
            return net == expected ? [] : [
                InvarianceViolation(
                    AccountingInvarianceReason.transaction_amount_inconsistent(
                        gross: amount.gross,
                        fee: fee,
                        net: net,
                        expected_net: expected
                    ),
                    path: [.field("net")]
                )
            ]
        }
    }
}

public extension InvarianceRule where Value == TransactionAmount {
    static var transaction: AccountingTransactionAmountInvarianceRules { .init() }
}

public struct AccountingCurrencyInvarianceRules: Sendable {
    public init() {}

    public func valid(
        supported: Set<String>
    ) -> InvarianceRule<TransactionAmount> {
        InvarianceRule { amount in
            supported.contains(amount.currency) ? [] : [
                InvarianceViolation(
                    AccountingInvarianceReason.unsupported_currency(
                        actual: amount.currency,
                        supported: supported
                    ),
                    path: [.field("currency")]
                )
            ]
        }
    }
}

public extension InvarianceRule where Value == TransactionAmount {
    static var currency: AccountingCurrencyInvarianceRules { .init() }
}

public struct AccountingTransactionInvarianceRules: Sendable {
    public init() {}

    public var identified: InvarianceRule<Transaction> {
        InvarianceRule { transaction in
            transaction.id == nil ? [
                InvarianceViolation(
                    AccountingInvarianceReason.transaction_missing_id,
                    path: [.field("id")]
                )
            ] : []
        }
    }
}

public extension InvarianceRule where Value == Transaction {
    static var transaction: AccountingTransactionInvarianceRules { .init() }
}

public struct AccountingTransactionCollectionInvarianceRules: Sendable {
    public init() {}

    /// Mirrors TransactionStore's current semantics: nil IDs are ignored.
    public var unique_ids: InvarianceRule<[Transaction]> {
        InvarianceRule { transactions in
            var first_seen: [Int: Int] = [:]
            var violations: [InvarianceViolation] = []
            for (index, transaction) in transactions.enumerated() {
                guard let id = transaction.id else { continue }
                if let first_index = first_seen[id] {
                    violations.append(
                        InvarianceViolation(
                            AccountingInvarianceReason.transaction_duplicate_id(
                                id: id,
                                first_index: first_index,
                                duplicate_index: index
                            ),
                            path: [.index(index), .field("id")]
                        )
                    )
                } else {
                    first_seen[id] = index
                }
            }
            return violations
        }
    }
}

public extension InvarianceRule where Value == [Transaction] {
    static var transaction: AccountingTransactionCollectionInvarianceRules { .init() }
}

public struct AccountingReferenceInvarianceRules: Sendable {
    public init() {}

    public func resolved(in store: TransactionStore) -> InvarianceRule<[TransactionKey]> {
        InvarianceRule { keys in
            keys.enumerated().compactMap { index, key in
                store.byID[key] == nil ? InvarianceViolation(
                    AccountingInvarianceReason.transaction_reference_missing(key.id),
                    path: [.index(index)]
                ) : nil
            }
        }
    }
}

public extension InvarianceRule where Value == [TransactionKey] {
    static var references: AccountingReferenceInvarianceRules { .init() }
}

public struct AccountingAccountReferenceInvarianceRules: Sendable {
    public init() {}

    public func exists(
        where contains: @escaping @Sendable (AccountKey) -> Bool
    ) -> InvarianceRule<ResolvedLine> {
        InvarianceRule { line in
            contains(line.account) ? [] : [
                InvarianceViolation(
                    AccountingInvarianceReason.account_reference_missing(line.account),
                    path: [.field("account")]
                )
            ]
        }
    }
}

public extension InvarianceRule where Value == ResolvedLine {
    static var account: AccountingAccountReferenceInvarianceRules { .init() }
}

public struct AccountingEntityReferenceInvarianceRules: Sendable {
    public init() {}

    public func exists(
        where contains: @escaping @Sendable (EntityKey) -> Bool
    ) -> InvarianceRule<ResolvedLine> {
        InvarianceRule { line in
            contains(line.entity) ? [] : [
                InvarianceViolation(
                    AccountingInvarianceReason.entity_reference_missing(line.entity),
                    path: [.field("entity")]
                )
            ]
        }
    }
}

public extension InvarianceRule where Value == ResolvedLine {
    static var entity: AccountingEntityReferenceInvarianceRules { .init() }
}

public struct AccountingAllocationInvarianceRules: Sendable {
    public init() {}

    public func totals_equal(to expected: Decimal) -> InvarianceRule<[Decimal]> {
        InvarianceRule { amounts in
            let total = amounts.reduce(Decimal.zero, +)
            guard !total.isNaN else {
                return [InvarianceViolation(InvarianceNonfiniteNumber(actual: total))]
            }
            return total == expected ? [] : [
                InvarianceViolation(
                    AccountingInvarianceReason.allocation_total_mismatch(
                        expected: expected,
                        actual: total
                    )
                )
            ]
        }
    }
}

public extension InvarianceRule where Value == [Decimal] {
    static var allocation: AccountingAllocationInvarianceRules { .init() }
}
