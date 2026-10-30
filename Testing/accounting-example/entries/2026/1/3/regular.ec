// Fictional entries (split by year / quarter / month).

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
