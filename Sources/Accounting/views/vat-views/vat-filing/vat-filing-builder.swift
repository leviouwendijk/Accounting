
import Foundation

public enum VATFilingBuilder {
    public static func build(
        resolvedEntries: [ResolvedEntry],
        chart: CompiledChart,
        window: PeriodWindow,
        targetPeriod: VATPeriod,
        statusQuarter: VATStatusQuarter?,
        balanceSheetNetPosition: Decimal?,
        title: String = "VAT filing",
        calendar: Calendar,
        businessEntity: BusinessEntity = .vof
    ) throws -> VATFilingReport {
        let roots = businessEntity.vatRoots
        let analytics = businessEntity.analyticsRoots

        let maps = try RGSAssembler.makeMaps(
            from: chart
        )

        let nodes = chart.nodes

        let idByCode = Dictionary(
            uniqueKeysWithValues: nodes.map {
                ($0.codes.code, $0.id)
            }
        )

        let labelByCode = Dictionary(
            uniqueKeysWithValues: nodes.map {
                ($0.codes.code, $0.labels.short)
            }
        )

        let directionByCode: [String: Direction] = Dictionary(
            uniqueKeysWithValues: nodes.compactMap { node in
                guard let direction = node.direction else {
                    return nil
                }

                return (node.codes.code, direction)
            }
        )

        func label(
            for code: String
        ) -> String {
            labelByCode[code] ?? code
        }

        func presented(
            raw: Decimal,
            code: String
        ) -> Decimal {
            let direction = directionByCode[code] ?? .debit

            return RGSAssembler.present(
                raw,
                direction: direction,
                mode: .apply
            )
        }

        var turnoverByCode: [String: Decimal] = [:]
        var turnoverEntryIDsByCode: [String: Set<Int>] = [:]

        var vatByCode: [String: Decimal] = [:]
        var vatEntryIDsByCode: [String: Set<Int>] = [:]
        var allVATRootRaw: Decimal = 0

        for entry in resolvedEntries {
            guard case .absolute(let postingDate) = entry.date else {
                continue
            }

            let postingPeriod = period(
                containing: postingDate,
                calendar: calendar
            )

            let shouldIncludeOrdinaryPosting =
                entry.vat == nil
                    && postingPeriod == targetPeriod
                    && contains(postingDate, in: window)

            let shouldIncludeCorrection =
                entry.vat?.kind == .correction
                    && entry.vat?.period == targetPeriod

            guard shouldIncludeOrdinaryPosting || shouldIncludeCorrection else {
                continue
            }

            for line in entry.lines {
                let code = line.account.code
                let raw = signedRaw(line)

                if matchesAnyPrefix(
                    code,
                    prefixes: [analytics.netTurnoverCode]
                ) {
                    turnoverByCode[code, default: 0] += raw

                    if let entryID = entry.id {
                        turnoverEntryIDsByCode[code, default: []].insert(entryID)
                    }
                }

                guard isVATRootCode(
                    code,
                    roots: roots
                ) else {
                    continue
                }

                allVATRootRaw += raw
                vatByCode[code, default: 0] += raw

                if let entryID = entry.id {
                    vatEntryIDsByCode[code, default: []].insert(entryID)
                }
            }
        }

        let turnoverRows = makeSourceRows(
            amountsByCode: turnoverByCode,
            entryIDsByCode: turnoverEntryIDsByCode,
            label: label,
            present: { code, raw in
                presented(raw: raw, code: code)
            },
            maps: maps,
            idByCode: idByCode
        )

        let totalTurnover = turnoverRows.reduce(Decimal(0)) {
            $0 + $1.amount
        }

        let outputCodes = roots.outputCodes

        let nonZeroOutputCodes = outputCodes.filter { outputCode in
            vatByCode.contains { code, raw in
                raw != 0 && code.hasPrefix(outputCode)
            }
        }

        let turnoverOutputCode = nonZeroOutputCodes.count == 1
            ? nonZeroOutputCodes[0]
            : nil

        let attachTurnoverToOutput =
            turnoverOutputCode != nil
                && !turnoverRows.isEmpty

        var classifiedCodes = Set<String>()
        var vatRows: [VATFilingVATRow] = []

        vatRows += makeVATRows(
            family: .output,
            codes: roots.outputCodes,
            amountsByCode: vatByCode,
            entryIDsByCode: vatEntryIDsByCode,
            label: label,
            presentVAT: presentVATAmount,
            turnoverProvider: { code in
                guard let turnoverOutputCode,
                      code == turnoverOutputCode
                else {
                    return nil
                }

                return totalTurnover
            },
            maps: maps,
            idByCode: idByCode,
            classifiedCodes: &classifiedCodes
        )

        vatRows += makeVATRows(
            family: .deductible,
            codes: roots.deductibleCodes,
            amountsByCode: vatByCode,
            entryIDsByCode: vatEntryIDsByCode,
            label: label,
            presentVAT: presentVATAmount,
            turnoverProvider: { _ in nil },
            maps: maps,
            idByCode: idByCode,
            classifiedCodes: &classifiedCodes
        )

        vatRows += makeVATRows(
            family: .privateUse,
            codes: roots.privateUseCodes,
            amountsByCode: vatByCode,
            entryIDsByCode: vatEntryIDsByCode,
            label: label,
            presentVAT: presentVATAmount,
            turnoverProvider: { _ in nil },
            maps: maps,
            idByCode: idByCode,
            classifiedCodes: &classifiedCodes
        )

        let otherRows = makeOtherVATRows(
            amountsByCode: vatByCode,
            entryIDsByCode: vatEntryIDsByCode,
            excludedCodes: classifiedCodes,
            roots: roots,
            label: label,
            presentVAT: presentVATAmount,
            maps: maps,
            idByCode: idByCode
        )

        let includedVATRaw =
            vatRows.reduce(Decimal(0)) { $0 + $1.rawVAT }
                + otherRows.reduce(Decimal(0)) { $0 + $1.rawVAT }

        let currentReturnRaw = includedVATRaw
        let currentPayable = currentReturnRaw < 0
            ? -currentReturnRaw
            : 0
        let currentReceivable = currentReturnRaw > 0
            ? currentReturnRaw
            : 0

        let carryLedger = VATResidualLedgerBuilder.buildCarryIn(
            resolvedEntries: resolvedEntries,
            chart: chart,
            targetPeriod: targetPeriod,
            calendar: calendar,
            businessEntity: businessEntity
        )

        let carryRows = carryLedger.lots.map {
            VATFilingCarryRow(
                sourcePeriod: $0.sourcePeriod,
                entryId: $0.entryId,
                family: $0.family,
                code: $0.code,
                label: $0.label,
                amount: $0.remainingAmount,
                isFileableRubricCarry: $0.isFileableRubricCarry,
                isSettlementRemainder: $0.isSettlementRemainder
            )
        }

        let carryIn = carryLedger.totalRaw

        let expectedSettlementRaw =
            carryIn + currentReturnRaw

        let expectedPayable = expectedSettlementRaw < 0
            ? -expectedSettlementRaw
            : 0
        let expectedReceivable = expectedSettlementRaw > 0
            ? expectedSettlementRaw
            : 0

        let statusDifference = balanceSheetNetPosition.map {
            $0 - DecimalFuncs.absDec(expectedSettlementRaw)
        }

        let unclassifiedDifference = allVATRootRaw - includedVATRaw

        let filingBalanceRows = makeFilingBalanceRows(
            vatRows: vatRows + otherRows,
            carryRows: carryRows,
            label: label,
            presentVAT: presentVATAmount,
            maps: maps,
            idByCode: idByCode
        )

        let filingBalanceRaw = filingBalanceRows.reduce(Decimal(0)) {
            $0 + $1.filingRaw
        }

        var warnings: [String] = []

        if turnoverRows.isEmpty {
            warnings.append(
                "No turnover rows were found under \(analytics.netTurnoverCode)."
            )
        }

        if !attachTurnoverToOutput, !turnoverRows.isEmpty {
            warnings.append(
                "Turnover was not assigned to a VAT output row because zero or multiple output rows have VAT movement."
            )
        }

        if unclassifiedDifference != 0 {
            warnings.append(
                "VAT root movement does not reconcile with rendered VAT rows. Difference: \(unclassifiedDifference)."
            )
        }

        if let statusDifference,
           DecimalFuncs.absDec(statusDifference) > Decimal(string: "0.01")! {
            warnings.append(
                "Balance-sheet VAT overview differs from filing/status expected settlement by \(statusDifference)."
            )
        }

        if let statusQuarter {
            let scalarCarryDifference = statusQuarter.carryIn - carryIn

            if DecimalFuncs.absDec(scalarCarryDifference) > Decimal(string: "0.01")! {
                warnings.append(
                    "Open VAT lot carry-in differs from scalar VAT status carry-in by \(scalarCarryDifference)."
                )
            }
        }

        if carryLedger.settlementRemainderRaw != 0 {
            warnings.append(
                "Carry-in includes settlement/payment remainder of \(carryLedger.settlementRemainderRaw). Do not file that as a VAT rubric without tracing the payment."
            )
        }

        let filingBalanceDifference =
            filingBalanceRaw - expectedSettlementRaw

        if DecimalFuncs.absDec(filingBalanceDifference) > Decimal(string: "0.01")! {
            warnings.append(
                "Filable VAT balances do not equal expected settlement by \(filingBalanceDifference). Some carry-in is not fileable as a rubric."
            )
        }

        return VATFilingReport(
            title: title,
            period: targetPeriod,
            turnoverRows: turnoverRows,
            vatRows: vatRows,
            otherVATRows: otherRows,
            carryRows: carryRows,
            filingBalanceRows: filingBalanceRows,
            reconciliation: .init(
                currentReturnRaw: currentReturnRaw,
                currentPayable: currentPayable,
                currentReceivable: currentReceivable,
                carryIn: carryIn,
                expectedSettlementRaw: expectedSettlementRaw,
                expectedPayable: expectedPayable,
                expectedReceivable: expectedReceivable,
                balanceSheetNetPosition: balanceSheetNetPosition,
                statusDifference: statusDifference,
                includedVATRaw: includedVATRaw,
                allVATRootRaw: allVATRootRaw,
                unclassifiedDifference: unclassifiedDifference
            ),
            warnings: warnings
        )
    }

    public static func period(
        containing date: Date,
        calendar: Calendar
    ) -> VATPeriod {
        let year = calendar.component(
            .year,
            from: date
        )

        let month = calendar.component(
            .month,
            from: date
        )

        let quarter: VATQuarter = switch month {
        case 1...3:
            .q1

        case 4...6:
            .q2

        case 7...9:
            .q3

        default:
            .q4
        }

        return VATPeriod(
            year: year,
            quarter: quarter
        )
    }
}

private extension VATFilingBuilder {
    struct FilingBalanceSeed {
        var family: VATFilingFamily
        var code: String
        var label: String
        var turnover: Decimal?
        var currentRaw: Decimal
        var carryRaw: Decimal
    }

    static func makeFilingBalanceRows(
        vatRows: [VATFilingVATRow],
        carryRows: [VATFilingCarryRow],
        label: (String) -> String,
        presentVAT: (VATFilingFamily, Decimal) -> Decimal,
        maps: RGSAssemblerResult,
        idByCode: [String: Int]
    ) -> [VATFilingBalanceRow] {
        var seeds: [String: FilingBalanceSeed] = [:]

        for row in vatRows {
            var seed = seeds[row.code] ?? FilingBalanceSeed(
                family: row.family,
                code: row.code,
                label: row.label,
                turnover: row.turnover,
                currentRaw: 0,
                carryRaw: 0
            )

            seed.family = row.family
            seed.label = row.label
            seed.turnover = row.turnover
            seed.currentRaw += row.rawVAT

            seeds[row.code] = seed
        }

        for row in carryRows where row.isFileableRubricCarry {
            let family = filingFamily(
                row.family
            )

            var seed = seeds[row.code] ?? FilingBalanceSeed(
                family: family,
                code: row.code,
                label: row.label.isEmpty ? label(row.code) : row.label,
                turnover: nil,
                currentRaw: 0,
                carryRaw: 0
            )

            seed.family = family
            seed.label = row.label.isEmpty ? label(row.code) : row.label
            seed.carryRaw += row.amount

            seeds[row.code] = seed
        }

        return seeds.values
            .map { seed in
                let filingRaw = seed.currentRaw + seed.carryRaw

                return VATFilingBalanceRow(
                    family: seed.family,
                    code: seed.code,
                    label: seed.label,
                    turnover: seed.turnover,
                    currentRaw: seed.currentRaw,
                    carryRaw: seed.carryRaw,
                    filingRaw: filingRaw,
                    currentVAT: presentVAT(seed.family, seed.currentRaw),
                    carryVAT: presentVAT(seed.family, seed.carryRaw),
                    filingVAT: presentVAT(seed.family, filingRaw)
                )
            }
            .filter {
                $0.currentRaw != 0
                    || $0.carryRaw != 0
                    || $0.filingRaw != 0
            }
            .sorted {
                sortKey($0.code, maps: maps, idByCode: idByCode)
                    < sortKey($1.code, maps: maps, idByCode: idByCode)
            }
    }

    static func filingFamily(
        _ family: VATStatusFamily
    ) -> VATFilingFamily {
        switch family {
        case .output:
            return .output

        case .deductible:
            return .deductible

        case .privateUse:
            return .privateUse

        case .receivable:
            return .receivable

        case .payableFallback:
            return .payableFallback
        }
    }
    static func makeSourceRows(
        amountsByCode: [String: Decimal],
        entryIDsByCode: [String: Set<Int>],
        label: (String) -> String,
        present: (String, Decimal) -> Decimal,
        maps: RGSAssemblerResult,
        idByCode: [String: Int]
    ) -> [VATFilingSourceRow] {
        amountsByCode
            .filter { _, value in value != 0 }
            .map { code, raw in
                VATFilingSourceRow(
                    code: code,
                    label: label(code),
                    amount: present(code, raw),
                    entryIDs: Array(entryIDsByCode[code] ?? []).sorted()
                )
            }
            .sorted {
                sortKey($0.code, maps: maps, idByCode: idByCode)
                    < sortKey($1.code, maps: maps, idByCode: idByCode)
            }
    }

    static func makeVATRows(
        family: VATFilingFamily,
        codes: [String],
        amountsByCode: [String: Decimal],
        entryIDsByCode: [String: Set<Int>],
        label: (String) -> String,
        presentVAT: (VATFilingFamily, Decimal) -> Decimal,
        turnoverProvider: (String) -> Decimal?,
        maps: RGSAssemblerResult,
        idByCode: [String: Int],
        classifiedCodes: inout Set<String>
    ) -> [VATFilingVATRow] {
        var rows: [VATFilingVATRow] = []

        for code in codes {
            let matching = amountsByCode.filter {
                $0.key.hasPrefix(code)
            }

            let raw = matching.values.reduce(Decimal(0), +)

            if raw == 0 {
                continue
            }

            for matchedCode in matching.keys {
                classifiedCodes.insert(matchedCode)
            }

            let sourceRows = makeSourceRows(
                amountsByCode: matching,
                entryIDsByCode: entryIDsByCode,
                label: label,
                present: { _, raw in
                    presentVAT(family, raw)
                },
                maps: maps,
                idByCode: idByCode
            )

            rows.append(
                VATFilingVATRow(
                    family: family,
                    code: code,
                    label: label(code),
                    turnover: turnoverProvider(code),
                    vat: presentVAT(family, raw),
                    rawVAT: raw,
                    sourceRows: sourceRows
                )
            )
        }

        return rows.sorted {
            sortKey($0.code, maps: maps, idByCode: idByCode)
                < sortKey($1.code, maps: maps, idByCode: idByCode)
        }
    }

    static func makeOtherVATRows(
        amountsByCode: [String: Decimal],
        entryIDsByCode: [String: Set<Int>],
        excludedCodes: Set<String>,
        roots: VATRoots,
        label: (String) -> String,
        presentVAT: (VATFilingFamily, Decimal) -> Decimal,
        maps: RGSAssemblerResult,
        idByCode: [String: Int]
    ) -> [VATFilingVATRow] {
        let remaining = amountsByCode.filter { code, value in
            value != 0
                && !excludedCodes.contains(code)
                && isVATRootCode(
                    code,
                    roots: roots
                )
        }

        return remaining.map { code, raw in
            VATFilingVATRow(
                family: classifiedFallbackFamily(
                    code,
                    roots: roots
                ),
                code: code,
                label: label(code),
                turnover: nil,
                vat: presentVAT(.other, raw),
                rawVAT: raw,
                sourceRows: [
                    VATFilingSourceRow(
                        code: code,
                        label: label(code),
                        amount: presentVAT(.other, raw),
                        entryIDs: Array(entryIDsByCode[code] ?? []).sorted()
                    )
                ]
            )
        }
        .sorted {
            sortKey($0.code, maps: maps, idByCode: idByCode)
                < sortKey($1.code, maps: maps, idByCode: idByCode)
        }
    }

    static func presentVATAmount(
        family: VATFilingFamily,
        raw: Decimal
    ) -> Decimal {
        switch family {
        case .output, .privateUse, .payableFallback:
            return raw < 0 ? -raw : raw

        case .deductible, .receivable:
            return raw < 0 ? -raw : raw

        case .other:
            return raw < 0 ? -raw : raw
        }
    }

    static func classifiedFallbackFamily(
        _ code: String,
        roots: VATRoots
    ) -> VATFilingFamily {
        if roots.receivableCodes.contains(where: { code.hasPrefix($0) }) {
            return .receivable
        }

        if roots.payableCodes.contains(where: { code.hasPrefix($0) }) {
            return .payableFallback
        }

        return .other
    }

    static func contains(
        _ date: Date,
        in window: PeriodWindow
    ) -> Bool {
        if let from = window.from,
           date < from {
            return false
        }

        if let to = window.to,
           date > to {
            return false
        }

        return true
    }

    static func isVATRootCode(
        _ code: String,
        roots: VATRoots
    ) -> Bool {
        guard !roots.excludedCodes.contains(where: { code.hasPrefix($0) }) else {
            return false
        }

        let prefixes =
            roots.outputCodes
                + roots.deductibleCodes
                + roots.privateUseCodes
                + roots.receivableCodes
                + roots.payableCodes

        return matchesAnyPrefix(
            code,
            prefixes: prefixes
        )
    }

    static func matchesAnyPrefix(
        _ code: String,
        prefixes: [String]
    ) -> Bool {
        prefixes.contains {
            code.hasPrefix($0)
        }
    }

    static func signedRaw(
        _ line: ResolvedLine
    ) -> Decimal {
        line.direction == .debit
            ? line.amount
            : -line.amount
    }

    static func sortKey(
        _ code: String,
        maps: RGSAssemblerResult,
        idByCode: [String: Int]
    ) -> String {
        guard let id = idByCode[code] else {
            return code
        }

        return maps.sortKeyById[id] ?? code
    }
}
