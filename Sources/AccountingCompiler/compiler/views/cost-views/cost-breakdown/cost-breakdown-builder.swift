import Accounting
import Foundation

extension CostViews {
    public enum CostBreakdownBuilder {
        private enum Codes {
            static let root = "WBed"
            static let auto = "WBedAut"
            static let transport = "WBedTra"
            static let housing = "WBedHui"
            static let maintenance = "WBedEem"
            static let sales = "WBedVkk"
        }

        public static func build(
            period: PeriodWindow,
            chart: CompiledChart,
            bundle: StatementBundle,
            omslag: OmslagMode = .apply,
            tolerance: Decimal = 0
        ) throws -> CostBreakdownReport {
            let prepared = try chart.ensuringIndex(
                enrichNodes: true,
                strict: false
            )

            guard let index = prepared.index else {
                throw RGSAssemblerError.missingIndex
            }

            let maps = try RGSAssembler.makeMaps(from: prepared)
            let hierarchy = RGSIdentifierHierarchy.build(from: prepared.nodes)

            let nodeById = Dictionary(
                uniqueKeysWithValues: prepared.nodes.map { ($0.id, $0) }
            )

            let resolver = CanonicalRootAmountResolver(
                chart: prepared,
                bundle: bundle,
                maps: maps,
                omslag: omslag
            )

            let rootId = try id(
                for: Codes.root,
                in: index
            )

            let explicitCodes = [
                Codes.auto,
                Codes.transport,
                Codes.housing,
                Codes.maintenance,
                Codes.sales,
            ]

            let explicitIds = try explicitCodes.map {
                try id(for: $0, in: index)
            }

            for (code, id) in zip(explicitCodes, explicitIds) {
                guard hierarchy.parentById[id] == rootId else {
                    throw CostBreakdownError.codeOutsideScope(
                        code: code,
                        scope: Codes.root
                    )
                }
            }

            let childIds = immediateChildren(
                of: rootId,
                in: hierarchy.parentById
            )

            let sortedChildRoots = try childIds
                .map { id in
                    (
                        id: id,
                        member: try makeMember(
                            id: id,
                            nodeById: nodeById,
                            resolver: resolver
                        )
                    )
                }
                .sorted { lhs, rhs in
                    let lhsKey = maps.sortKeyById[lhs.id]
                        ?? lhs.member.code
                    let rhsKey = maps.sortKeyById[rhs.id]
                        ?? rhs.member.code
                    return lhsKey < rhsKey
                }

            let childRootTotal = rounded(
                sortedChildRoots.reduce(Decimal(0)) { partial, next in
                    partial + next.member.amount
                }
            )

            let sourceTotal = try shownAmount(
                for: Codes.root,
                using: resolver
            )

            let childRootDifference = rounded(
                sourceTotal - childRootTotal
            )

            let childRootMembersById = Dictionary(
                uniqueKeysWithValues: sortedChildRoots.map {
                    ($0.id, $0.member)
                }
            )

            let autoMember = try requiredMember(
                explicitIds[0],
                in: childRootMembersById,
                code: Codes.auto
            )
            let transportMember = try requiredMember(
                explicitIds[1],
                in: childRootMembersById,
                code: Codes.transport
            )
            let housingMember = try requiredMember(
                explicitIds[2],
                in: childRootMembersById,
                code: Codes.housing
            )
            let maintenanceMember = try requiredMember(
                explicitIds[3],
                in: childRootMembersById,
                code: Codes.maintenance
            )
            let salesMember = try requiredMember(
                explicitIds[4],
                in: childRootMembersById,
                code: Codes.sales
            )

            let explicitBuckets: [CostBreakdownBucket] = [
                .init(
                    key: .autoEnTransport,
                    amount: rounded(
                        autoMember.amount + transportMember.amount
                    ),
                    matchedCodes: [
                        Codes.auto,
                        Codes.transport,
                    ],
                    members: [
                        autoMember,
                        transportMember,
                    ]
                ),
                .init(
                    key: .huisvestingskosten,
                    amount: housingMember.amount,
                    matchedCodes: [Codes.housing],
                    members: [housingMember]
                ),
                .init(
                    key: .onderhoudOverigeMaterieleVasteActiva,
                    amount: maintenanceMember.amount,
                    matchedCodes: [Codes.maintenance],
                    members: [maintenanceMember]
                ),
                .init(
                    key: .verkoopkosten,
                    amount: salesMember.amount,
                    matchedCodes: [Codes.sales],
                    members: [salesMember]
                ),
            ]

            let explicitIdSet = Set(explicitIds)

            let otherRoots = sortedChildRoots.filter { pair in
                !explicitIdSet.contains(pair.id)
            }

            let otherMembers = otherRoots.map(\.member)

            let explicitTotal = rounded(
                explicitBuckets.reduce(Decimal(0)) { partial, bucket in
                    partial + bucket.amount
                }
            )

            let otherResidual = rounded(
                sourceTotal - explicitTotal
            )

            let otherChildrenTotal = rounded(
                otherMembers.reduce(Decimal(0)) { partial, member in
                    partial + member.amount
                }
            )

            let otherDifference = rounded(
                otherResidual - otherChildrenTotal
            )

            let otherBucket = CostBreakdownBucket(
                key: .andereKosten,
                amount: otherResidual,
                matchedCodes: otherMembers.map(\.code),
                members: otherMembers
            )

            let buckets = (
                explicitBuckets + [otherBucket]
            )
            .sorted { lhs, rhs in
                lhs.key.sortOrder < rhs.key.sortOrder
            }

            let bucketTotal = rounded(
                buckets.reduce(Decimal(0)) { partial, bucket in
                    partial + bucket.amount
                }
            )

            let difference = rounded(
                sourceTotal - bucketTotal
            )

            let sourceLabel = nodeById[rootId]?.labels.short
                ?? Codes.root

            let reconciliation = CostBreakdownReconciliation(
                sourceCode: Codes.root,
                sourceLabel: sourceLabel,
                sourceTotal: sourceTotal,
                childRootTotal: childRootTotal,
                childRootDifference: childRootDifference,
                bucketTotal: bucketTotal,
                difference: difference,
                otherResidual: otherResidual,
                otherChildrenTotal: otherChildrenTotal,
                otherDifference: otherDifference,
                tolerance: tolerance,
                passed:
                    !exceeds(difference, tolerance: tolerance)
                    && !exceeds(childRootDifference, tolerance: tolerance)
                    && !exceeds(otherDifference, tolerance: tolerance)
            )

            guard reconciliation.passed else {
                throw CostBreakdownError.reconciliationFailed(
                    sourceCode: reconciliation.sourceCode,
                    difference: reconciliation.difference,
                    childRootDifference: reconciliation.childRootDifference,
                    otherDifference: reconciliation.otherDifference,
                    tolerance: reconciliation.tolerance
                )
            }

            return .init(
                title: "Overige bedrijfskosten",
                period: period,
                buckets: buckets,
                reconciliation: reconciliation
            )
        }

        @inline(__always)
        private static func id(
            for code: String,
            in index: RGSIndex
        ) throws -> Int {
            guard let id = index.byIdentifier[code] else {
                throw CostBreakdownError.missingCode(code)
            }

            return id
        }

        @inline(__always)
        private static func shownAmount(
            for code: String,
            using resolver: CanonicalRootAmountResolver
        ) throws -> Decimal {
            guard let amount = resolver.shownAmount(for: code) else {
                throw CostBreakdownError.missingCode(code)
            }

            return rounded(amount)
        }

        @inline(__always)
        private static func makeMember(
            id: Int,
            nodeById: [Int: RGSNode],
            resolver: CanonicalRootAmountResolver
        ) throws -> CostBreakdownBucketMember {
            guard let node = nodeById[id] else {
                throw CostBreakdownError.missingCode("#\(id)")
            }

            let code = node.codes.code

            return .init(
                code: code,
                label: node.labels.short,
                amount: try shownAmount(
                    for: code,
                    using: resolver
                )
            )
        }

        @inline(__always)
        private static func requiredMember(
            _ id: Int,
            in membersById: [Int: CostBreakdownBucketMember],
            code: String
        ) throws -> CostBreakdownBucketMember {
            guard let member = membersById[id] else {
                throw CostBreakdownError.missingCode(code)
            }

            return member
        }

        @inline(__always)
        private static func immediateChildren(
            of parentId: Int,
            in parentById: [Int: Int?]
        ) -> [Int] {
            parentById.compactMap { childId, maybeParent in
                maybeParent == parentId ? childId : nil
            }
        }

        @inline(__always)
        private static func rounded(
            _ value: Decimal
        ) -> Decimal {
            AccountingMoney.round(value)
        }

        @inline(__always)
        private static func absolute(
            _ value: Decimal
        ) -> Decimal {
            value < 0 ? -value : value
        }

        @inline(__always)
        private static func exceeds(
            _ value: Decimal,
            tolerance: Decimal
        ) -> Bool {
            absolute(value) > tolerance
        }
    }
}
