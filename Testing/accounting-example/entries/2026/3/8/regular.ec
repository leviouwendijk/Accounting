// Fictional entries (split by year / quarter / month).

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
