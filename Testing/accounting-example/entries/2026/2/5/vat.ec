// Fictional Q2 expense. Input VAT 42 on 200 net.
entry {
    id = 9902
    date = 2026-05-15
    sort regular
    for (audit_expense) in (WBedAlkOal) { debit = 200.00 }
    for (audit_expense) in (BSchBepBtwVoo) { debit = 42.00 }
    for (audit_bank) in (BLimBanRba) { credit = 242.00 }
    transactions { ref 7902 }
}
