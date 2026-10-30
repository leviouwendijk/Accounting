// Fictional entries (split by year / quarter / month).

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
