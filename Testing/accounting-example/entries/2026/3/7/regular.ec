// Fictional entries (split by year / quarter / month).

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
