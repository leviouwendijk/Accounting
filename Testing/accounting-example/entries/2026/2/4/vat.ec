// Fictional Q2 VAT sale. VAT exclusive 1000, output VAT 210.
entry {
    id = 9901
    date = 2026-04-15
    sort regular
    for (audit_bank) in (BLimBanRba) { debit = 1210.00 }
    for (audit_revenue) in (WOmzNodOdh) { credit = 1000.00 }
    for (audit_revenue) in (BSchBepBtwOla) { credit = 210.00 }
    transactions { ref 7901 }
}
