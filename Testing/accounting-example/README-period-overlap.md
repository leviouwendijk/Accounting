# Synthetic Accounting period-overlap audit

This is a **fictional** project fixture, not financial data. It is designed to reproduce or falsify the suspected double counting in `PeriodAssembler` without editing any accounting logic.

**Existing files are intentionally untouched**: `config/settings.ec` and `config/resources/rgs/v3_8.json` are provided by the project owner. The generated files only add entities, journal entries and bank transactions. No actual tax or business records are used.

## Independent oracle

All entries balance debit and credit. Each matching transaction ID is unique and is linked from exactly one entry. The bank postings are the primary oracle because they are not affected by income-statement net-income overlays or owner-equity routing.

| Event/date | Change in bank (€) | Bank after event (€) |
|---|---:|---:|
| 2025-12-15 capital | +1,000 | 1,000 |
| 2025-12-22 revenue | +300 | 1,300 |
| 2026-01-10 revenue | +200 | 1,500 |
| 2026-01-11 expense | −50 | 1,450 |
| 2026-03-15 revenue | +400 | 1,850 |
| 2026-07-10 revenue | +600 | 2,450 |
| 2026-07-11 expense | −100 | 2,350 |
| 2026-08-05 revenue | +250 | 2,600 |
| 2026-08-12 expense | −75 | **2,525** |
| 2026-08-25 revenue | +500 | **3,025** |
| 2026-09-10 revenue | +900 | **3,925** |

### Expected statements (bank leaf `BLimBanRba`)

| Command | Reporting window | Expected bank balance (€) | Expected profit for reporting window (€) |
|---|---|---:|---:|
| Month, `--to-date --anchor 2026-08-15` | Aug 1–15, 2026 | **2,525** | 175 |
| Month, `--anchor 2026-08-15` | Whole August 2026 | **3,025** | 675 |
| Year, `--to-date --anchor 2026-08-15` | Jan 1–Aug 15, 2026 | **2,525** | 1,225 |
| Year, `--anchor 2026-08-15` | Whole 2026 | **3,925** | 2,625 |
| Lifetime | All entries | **3,925** | 2,925 across all periods |

Profit is revenue minus expenses in the designated reporting window, not an assertion about the placement of that amount in the balance-sheet net-income overlay. The previous year's 2025 profit is €300; there are no tax or VAT postings in this scenario.

If historical values are doubled when `--to-date` is set, predicted *incorrect* bank figures for the current implementation are August-to-date **€4,875** (= €2,350 opening + €2,525 cumulative movements) and year-to-date **€3,825** (= €1,300 opening + €2,525 cumulative movements). Lifetime may also become **€7,850** if both historical and full-window seeds include all entries. These are hypotheses to check against actual compiler output, **not verified observations**.

## Run using the real compiler

From the `Accounting` package root:

```sh
swift run ec period month --project Testing/accounting-example --anchor 2026-08-15 --to-date
swift run ec period month --project Testing/accounting-example --anchor 2026-08-15
swift run ec period year --project Testing/accounting-example --anchor 2026-08-15 --to-date
swift run ec period year --project Testing/accounting-example --anchor 2026-08-15
swift run ec period lifetime --project Testing/accounting-example --anchor 2026-08-15
```

No `--pdf` or other writer flags are requested. Native projections are used by default. Run each invocation separately and compare the bank balance, net income, total balance-sheet equality, and any diagnostics. A balanced statement by itself is **not** proof against duplicated movement, because both sides of the original journal can be duplicated.

Important: If the compiler fails to resolve any account or entity, preserve that error and verify the provided chart contains the referenced postable code. Do not change the production assembler or relax account checks merely to make this test pass.

## Implications

A reproduced bank-balance discrepancy would confirm a statement-assembly bug for these request modes. It would **not**, by itself, prove that any filed income-tax return was misstated. Tax impact requires comparing the exact filing calculations and filed amounts with an independent ledger reconciliation.
