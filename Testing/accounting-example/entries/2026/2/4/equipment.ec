// Fictional capital expenditure, no input VAT (intentionally excluded from VAT fixture).
entry {
    id = 9950
    date = 2026-04-01
    sort regular
    for (demo_equipment#camera) in (BMvaMeiAkpIna) { debit = 1200.00 }
    for (audit_bank) in (BLimBanRba) { credit = 1200.00 }
    transactions { ref 7950 }
}
