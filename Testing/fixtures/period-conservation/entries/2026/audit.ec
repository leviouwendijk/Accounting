// Synthetic, balanced postings for 2026; IDs 9801–9811 are test-only.

// January service income: €200.00
entry {
    id = 9803
    date = 2026-01-10
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 200.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 200.00
    }

    transactions {
        ref 7803
    }
}

// January operating expense: €50.00
entry {
    id = 9804
    date = 2026-01-11
    sort regular

    for (audit_bank) in (BLimBanRba) {
        credit = 50.00
    }

    for (audit_expense) in (WBedAlkOal) {
        debit = 50.00
    }

    transactions {
        ref 7804
    }
}

// March service income: €400.00
entry {
    id = 9805
    date = 2026-03-15
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 400.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 400.00
    }

    transactions {
        ref 7805
    }
}

// July service income: €600.00
entry {
    id = 9806
    date = 2026-07-10
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 600.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 600.00
    }

    transactions {
        ref 7806
    }
}

// July operating expense: €100.00
entry {
    id = 9807
    date = 2026-07-11
    sort regular

    for (audit_bank) in (BLimBanRba) {
        credit = 100.00
    }

    for (audit_expense) in (WBedAlkOal) {
        debit = 100.00
    }

    transactions {
        ref 7807
    }
}

// Before-anchor August income: €250.00
entry {
    id = 9808
    date = 2026-08-05
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 250.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 250.00
    }

    transactions {
        ref 7808
    }
}

// Before-anchor August expense: €75.00
entry {
    id = 9809
    date = 2026-08-12
    sort regular

    for (audit_bank) in (BLimBanRba) {
        credit = 75.00
    }

    for (audit_expense) in (WBedAlkOal) {
        debit = 75.00
    }

    transactions {
        ref 7809
    }
}

// After-anchor August income: €500.00
entry {
    id = 9810
    date = 2026-08-25
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 500.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 500.00
    }

    transactions {
        ref 7810
    }
}

// After-August September income: €900.00
entry {
    id = 9811
    date = 2026-09-10
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 900.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 900.00
    }

    transactions {
        ref 7811
    }
}
