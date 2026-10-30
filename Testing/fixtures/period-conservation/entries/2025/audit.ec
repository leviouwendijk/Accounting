// Synthetic, balanced postings for 2025; IDs 9801–9811 are test-only.

// Prior-year partner capital: €1000.00
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

// Prior-year service income: €300.00
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
