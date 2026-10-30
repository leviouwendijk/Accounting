# Frozen period-conservation fixture

Fictional source journal and transactions, IDs 9801...9811 / 7801...7811. This folder is deliberately **not a standalone EC project**: `accounting-period-conservation` creates a temporary project, copying `config/` (including the existing RGS v3.8 chart) from `Testing/accounting-example` and copying this folder's `entries/` and `transactions/`. Only the frozen entries/transactions drive the oracle. Do not add VAT or asset scenarios here.

Golden bank positions: Aug 1–15 2026 = 2525, full Aug = 3025, Jan 1–Aug 15 = 2525, full 2026 = 3925, lifetime = 3925. Golden income: 175, 675, 1225, 2625, 2925 respectively.
