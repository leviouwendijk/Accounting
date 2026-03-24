// import HTML

// extension StatementHTMLRenderer {
//     @HTMLBuilder
//     static func renderBalanceTable(
//         _ title: String,
//         sec: RGSBalanceBucketsOutput.Section?
//     ) -> [any HTMLNode] {
//         if let sec {
//             HTML.h2 {
//                 HTML.text(title)
//             }

//             HTML.table(["class": "tbl"]) {
//                 HTML.thead {
//                     HTML.tr {
//                         HTML.th(["class": "col-label"]) {
//                             HTML.text("Naam")
//                         }
//                         HTML.th(["class": "col-amt"]) {
//                             HTML.text("Bedrag")
//                         }
//                     }
//                 }
//                 HTML.tbody {
//                     // Lines
//                     for line in sec.lines {
//                         let pad = String(
//                             repeating: "\u{00a0}\u{00a0}",
//                             count: max(0, line.relativeIndent)
//                         )

//                         HTML.tr {
//                             HTML.td(["class": "label"]) {
//                                 HTML.div([
//                                     "class": "sr-label \(levelClass(line.relativeIndent)) \(weightClass(line.relativeIndent))"
//                                 ]) {
//                                     HTML.raw(pad)
//                                     HTML.text(line.label)
//                                 }
//                             }
//                             HTML.td(["class": "amt"]) {
//                                 HTML.span([
//                                     "class": "sr-amount \(weightClass(line.relativeIndent))"
//                                 ]) {
//                                     HTML.text(fmt(line.amount))
//                                 }
//                             }
//                         }
//                     }

//                     // Subtotal row, if any
//                     if let st = sec.subtotal {
//                         HTML.tr(["class": "total"]) {
//                             HTML.td(["class": "label"]) {
//                                 HTML.text("Som")
//                             }
//                             HTML.td(["class": "amt"]) {
//                                 HTML.strong {
//                                     HTML.text(fmt(st))
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
//         }
//     }
// }
