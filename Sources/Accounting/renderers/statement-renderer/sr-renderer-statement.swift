
// RESTRUCTRUING
// ROLLBACK:

// import Foundation
// import HTML

// extension StatementHTMLRenderer {
//     public static func render(
//         period: PeriodAssembleResultPeriod,
//         chart: CompiledChart,
//         equityCode: String = "BEiv",
//         options: Options = .init()
//     ) throws -> String {
//         var opts = options
//         opts.subtitle = period.range.string()
//         return try render(bundle: period.bundle, chart: chart, equityCode: equityCode, options: opts)
//     }
// }

// extension StatementHTMLRenderer {
//     public static func render(
//         bundle: StatementBundle,
//         chart: CompiledChart,
//         equityCode: String = "BEiv",
//         options: Options = .init()
//     ) throws -> String {
//         // MODEL STEP: compute sections using your existing presenter helpers.
//         let sections = try RGSPrinter.computeBalanceByL2Sections(
//             bundle: bundle,
//             chart: chart,
//             equityCode: equityCode,
//             includeOtherBucket: options.includeOtherBucket
//         )

//         let isSections = try RGSPrinter.incomeSections(
//             bundle: bundle,
//             chart: chart,
//             omitLevel1Root: options.omitIncomeLevel1Root
//         )

//         let incomeLines = isSections.first?.lines ?? []

//         // Filter + indent, same logic as before.
//         let plRows: [(indent: Int, label: String, amount: Decimal, isTotal: Bool)] =
//             incomeLines
//                 .filter {
//                     options.minAbsIncome == 0 ? true : (absDec($0.amount) >= options.minAbsIncome)
//                 }
//                 .map { r in
//                     let base = options.omitIncomeLevel1Root ? 2 : 1
//                     return (
//                         indent: max(0, Int(r.level) - base),
//                         label: r.label,
//                         amount: r.amount,
//                         isTotal: false
//                     )
//                 }

//         let css = StatementStyleCSS.base().render()

//         let doc = HTML.document {
//             HTML.html(["lang": "nl"]) {
//                 HTML.head {
//                     HTML.meta(.charset())
//                     HTML.meta(.viewport())
//                     HTML.title(options.title)
//                     HTML.style(css)
//                 }

//                 HTML.body {
//                     // Header
//                     if let c = options.company {
//                         companyHeader(c, options: options)
//                     } else {
//                         HTML.h1 {
//                             HTML.text(escape(options.title))
//                         }
//                         if let sub = options.subtitle {
//                             HTML.div(["class": "subtitle"]) {
//                                 HTML.text(escape(sub))
//                             }
//                         }
//                     }

//                     // Winst- en verliesrekening
//                     HTML.h2 {
//                         HTML.text("Winst- en Verliesrekening")
//                     }

//                     HTML.table(["class": "tbl"]) {
//                         HTML.thead {
//                             HTML.tr {
//                                 HTML.th(["class": "col-label"]) {
//                                     HTML.text("Naam")
//                                 }
//                                 HTML.th(["class": "col-amt"]) {
//                                     HTML.text("Bedrag")
//                                 }
//                             }
//                         }
//                         HTML.tbody {
//                             for r in plRows {
//                                 let pad = String(
//                                     repeating: "\u{00a0}\u{00a0}",
//                                     count: max(0, r.indent)
//                                 )

//                                 HTML.tr {
//                                     HTML.td(["class": "label"]) {
//                                         HTML.div([
//                                             "class": "sr-label \(levelClass(r.indent)) \(weightClass(r.indent))"
//                                         ]) {
//                                             HTML.raw(pad)
//                                             if r.isTotal {
//                                                 HTML.strong {
//                                                     HTML.text(escape(r.label))
//                                                 }
//                                             } else {
//                                                 HTML.text(escape(r.label))
//                                             }
//                                         }
//                                     }

//                                     HTML.td(["class": "amt"]) {
//                                         HTML.span([
//                                             "class": "sr-amount \(weightClass(r.indent))"
//                                         ]) {
//                                             let txt = fmt(r.amount)
//                                             if r.isTotal {
//                                                 HTML.strong {
//                                                     HTML.text(txt)
//                                                 }
//                                             } else {
//                                                 HTML.text(txt)
//                                             }
//                                         }
//                                     }
//                                 }
//                             }
//                         }
//                     }

//                     // Balance sheet sections (Activa / Eigen Vermogen / Passiva / Other)
//                     renderBalanceTable("Balans: Activa",         sec: sections.assets)
//                     renderBalanceTable("Balans: Eigen Vermogen", sec: sections.equity)
//                     renderBalanceTable("Balans: Passiva",        sec: sections.liabilities)

//                     if options.includeOtherBucket {
//                         renderBalanceTable("Balance Sheet — Other", sec: sections.other)
//                     }

//                     // Summary check: Assets vs Equity + Liabilities
//                     if let sum = sections.summary {
//                         let ajk = sum.equity + sum.liabilities
//                         let ok  = (sum.assets == ajk)

//                         HTML.div(["class": "summary"]) {
//                             HTML.text("Som Activa: \(fmt(sum.assets))")
//                         }
//                         HTML.div(["class": "summary"]) {
//                             HTML.text("Som Eigen Vermogen + Passiva: \(fmt(ajk))")
//                         }
//                         HTML.div(["class": "summary"]) {
//                             if ok {
//                                 HTML.text("")
//                             } else {
//                                 HTML.span(["class": "warn"]) {
//                                     HTML.text("DIFF: " + fmt(sum.assets - ajk))
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }

//         // Pretty HTML with doctype via Constructors
//         return doc.render(default: .pretty, doctype: true)
//     }
// }
