// import Foundation

// public extension StatementHTMLRenderer {
//     static func renderVATOverviewHTML(
//         bundle: StatementBundle,
//         chart: CompiledChart,
//         options: Options = .init(title: "BTW / Taxes Overview"),
//         includeCorrections: Bool = true,
//         minAbs: Decimal = 0
//     ) throws -> String {
//         let overview = try RGSAssembler.vatOverview(
//             options.title, bundle: bundle, chart: chart,
//             includeCorrections: includeCorrections, minAbs: minAbs
//         )
//         return renderVATOverviewHTML(overview, options: options)
//     }

//     static func renderVATOverviewHTML(
//         _ overview: VATOverview,
//         options: Options = .init(title: "BTW / Taxes Overview")
//     ) -> String {
//         func fmt(_ x: Decimal) -> String {
//             let nf = NumberFormatter()
//             nf.locale = Locale(identifier: "nl_NL")
//             nf.numberStyle = .currency
//             nf.currencySymbol = options.currencySymbol
//             nf.minimumFractionDigits = 2
//             nf.maximumFractionDigits = 2
//             return nf.string(from: x as NSDecimalNumber) ?? x.description
//         }

//         var html: [String] = []
//         html.append("""
//         <!doctype html>
//         <html lang="nl">
//         <head>
//           <meta charset="utf-8">
//           <meta name="viewport" content="width=device-width, initial-scale=1">
//           <title>\(overview.title)</title>
//           <style>
//             :root {
//               --pad: 48px;
//               --row-pad: 10px 12px;
//               --border: #eee;
//               --muted: #666;
//               --neg: #b00020;
//               --indent-step: 16px; /* per level step */
//             }
//             body { font-family: -apple-system,BlinkMacSystemFont,Segoe UI,Roboto,Helvetica,Arial,sans-serif; margin: var(--pad); font-size: 12px; }
//             h1 { font-size: 20px; margin: 0 0 8px; }
//             h2 { font-size: 16px; margin: 24px 0 8px; }
//             .sub { color: var(--muted); margin: 0 0 24px; }
//             table { width: 100%; border-collapse: collapse; margin: 8px 0 16px; }
//             th, td { padding: var(--row-pad); border-bottom: 1px solid var(--border); }
//             th { text-align: left; font-weight: 600; }
//             th.amount, td.amount { text-align: right; white-space: nowrap; }
//             td.label { width: 60%; }
//             td.code { width: 20%; color: var(--muted); }
//             .neg { color: var(--neg); }
//             .summary { margin-top: 12px; }
//             .summary table { margin-top: 4px; }
//             .note { color: var(--muted); font-size: 11px; margin-top: 6px; }
//           </style>
//         </head>
//         <body>
//           <h1>\(overview.title)</h1>
//           \(options.subtitle.map { "<div class='sub'>\($0)</div>" } ?? "")
//         """)

//         // Sections
//         for section in overview.sections {
//             html.append("<h2>\(section.title)</h2>")
//             html.append("""
//             <table>
//               <thead>
//                 <tr>
//                   <th>Label</th>
//                   <th>Code</th>
//                   <th class="amount">Bedrag</th>
//                 </tr>
//               </thead>
//               <tbody>
//             """)
//             let base = section.rows.map({ $0.level }).min() ?? 0
//             for r in section.rows {
//                 let lvl = max(0, r.level - base)
//                 let indent = "style='padding-left: calc(var(--indent-step) * \(lvl));'"
//                 let cls = (r.amount < 0) ? " class='amount neg'" : " class='amount'"
//                 html.append("""
//                   <tr>
//                     <td class="label"><div \(indent)>\(r.label)</div></td>
//                     <td class="code">\(r.code)</td>
//                     <td\(cls)>\(fmt(r.amount))</td>
//                   </tr>
//                 """)
//             }
//             html.append("""
//               </tbody>
//             </table>
//             """)
//         }

//         // Summaries (including net position)
//         if !overview.summaries.isEmpty || overview.netPosition != nil {
//             html.append("<div class=\"summary\">")
//             html.append("<h2>Samenvatting</h2>")
//             html.append("""
//             <table>
//               <tbody>
//             """)
//             for s in overview.summaries {
//                 let cls = (s.amount < 0) ? " class='amount neg'" : " class='amount'"
//                 let code = s.code ?? "—"
//                 html.append("""
//                   <tr>
//                     <td class="label">\(s.label)</td>
//                     <td class="code">\(code)</td>
//                     <td\(cls)>\(fmt(s.amount))</td>
//                   </tr>
//                 """)
//             }
//             if let net = overview.netPosition {
//                 let cls = (net < 0) ? " class='amount neg'" : " class='amount'"
//                 html.append("""
//                   <tr>
//                     <td class="label"><strong>Netto BTW-positie (te betalen − te vorderen)</strong></td>
//                     <td class="code">—</td>
//                     <td\(cls)><strong>\(fmt(net))</strong></td>
//                   </tr>
//                 """)
//             }
//             html.append("""
//               </tbody>
//             </table>
//             </div>
//             """)
//         }

//         html.append("""
//           </body>
//         </html>
//         """)
//         return html.joined()
//     }
// }
