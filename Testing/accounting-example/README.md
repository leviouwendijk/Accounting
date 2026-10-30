# Accounting example project

Fictional financial data. This project illustrates a real EC folder structure: `config/`, `entries/<year>/<quarter>/<month>/`, and `transactions/<year>/<quarter>/<month>/`. Entries and bank transactions use unique IDs and may reference one another independently of filenames. Never place deprecated `.ec` postings inside `entries/`: the compiler loads all `.ec` files recursively.

The period-conservation fixture is **separate** under `Testing/fixtures/period-conservation`; the regression test materializes it in a temporary project and borrows the example's chart/settings. Adding entries here must not change that frozen oracle.

From the Accounting package root, run `swift run t_accounting` and inspect `swift run ec period month --project Testing/accounting-example --anchor 2026-08-15 --to-date`. The VAT scenario is recorded in `entries/2026/2/{4,5}/vat.ec` and `entries/2026/3/7/vat.ec` with corresponding transaction files. Q2 2026 has €1,000 turnover, €210 output VAT, €42 input VAT and a €21 July correction assigned to Q2: Q2 payable is €189. A separate July €33 ordinary VAT movement must not be assigned to Q2.

Run (from package root):

```sh
swift run ec vat filing --project Testing/accounting-example --quarter 2026Q2
swift run ec vat status quarter --project Testing/accounting-example --quarter 2026Q2
swift run ec vat audit --project Testing/accounting-example --quarter 2026Q2
swift run ec vat overview --project Testing/accounting-example --quarter 2026Q2
swift run t_accounting
```

The flow `accounting-example-vat-integration` loads the actual `.ec` files and checks exact signed numbers. These commands are verification steps; the ATP itself does not generate PDFs or transmit any return. The depreciation example adds one fictional €1,200 asset with 20% residual and four years of straight-line depreciation, commissioned 2026-04-01. Expected full-month depreciation is €20, with no postings initially. The compiler-backed test checks the April projection and missing posting; it does not mutate project data.

Run the audit read-only:

```sh
swift run ec depreciation --project Testing/accounting-example --detail monthly
swift run t_accounting
```

To check generation/idempotency, **copy the example project to a temporary writable directory first** (including `config/resources/rgs/v3_8.json`), then run `swift run ec depreciation write --project <temporary-copy> --month 2026-04` twice. The first invocation should fill April's €20 deficit, and the second should report no missing amount. Never point the writer at this version-controlled fixture. Inspect its output and the post-write depreciation audit before treating idempotency as verified. There are no live financial records in the example.
