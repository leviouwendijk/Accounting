// Fictional entries (split by year / quarter / month).

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
