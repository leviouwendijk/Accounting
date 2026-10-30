// Q3 correction targeting Q2, plus a separate ordinary Q3 VAT posting.
entry {
    id = 9903
    date = 2026-07-15
    sort regular
    for (audit_bank) in (BLimBanRba) { debit = 21.00 }
    for (audit_revenue) in (BSchBepBtwOla) { credit = 21.00 }
    vat { kind = correction period { year = 2026 quarter = 2 } }
    transactions { ref 7903 }
}
entry {
    id = 9904
    date = 2026-07-20
    sort regular
    for (audit_bank) in (BLimBanRba) { debit = 33.00 }
    for (audit_revenue) in (BSchBepBtwOla) { credit = 33.00 }
    transactions { ref 7904 }
}
