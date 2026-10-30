// Fictional entries (split by year / quarter / month).

entry {
    id = 9801
    date = 2025-12-15
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 1000.00
    }

    for (audit_owner) in (BEivKapPrsOns) {
        credit = 1000.00
    }

    transactions {
        ref 7801
    }
}

entry {
    id = 9802
    date = 2025-12-22
    sort regular

    for (audit_bank) in (BLimBanRba) {
        debit = 300.00
    }

    for (audit_revenue) in (WOmzNodOdh) {
        credit = 300.00
    }

    transactions {
        ref 7802
    }
}
