import Accounting
import Foundation
import HTML

extension StatementHTMLRenderer {
    @HTMLBuilder
    static func renderDocumentHeader(
        options: Options
    ) -> [any HTMLNode] {
        if let company = options.company {
            companyHeader(
                company,
                options: options
            )
        } else {
            basicHeader(options: options)
        }
    }

    @HTMLBuilder
    static func basicHeader(
        options: Options
    ) -> [any HTMLNode] {
        HTML.h1 {
            HTML.text(options.title)
        }

        if let subtitle = options.subtitle {
            HTML.div(["class": "subtitle"]) {
                HTML.text(subtitle)
            }
        }
    }

    static func companyHeader(
        _ company: Company,
        options: Options
    ) -> any HTMLNode {
        HTML.header(["class": "doc"]) {
            HTML.div(["class": "company"]) {
                let leftTitle = nonEmpty(company.name) ?? options.title

                HTML.h1 {
                    HTML.text(leftTitle)
                }

                if let kvk = company.kvk {
                    HTML.div(["class": "small"]) {
                        HTML.text(kvk)
                    }
                }

                if let address = company.address?.string,
                   !address.isEmpty {
                    for line in address.split(separator: "\n") {
                        HTML.div(["class": "small"]) {
                            HTML.text(String(line))
                        }
                    }
                }
            }

            HTML.div(["class": "meta"]) {
                HTML.div(["class": "title"]) {
                    HTML.text(options.title)
                }

                if let subtitle = options.subtitle {
                    HTML.div(["class": "subtitle"]) {
                        HTML.text(subtitle)
                    }
                }
            }
        }
    }
}

// extension StatementHTMLRenderer {
//     static func companyHeader(_ c: Company, options: Options) -> any HTMLNode {
//         HTML.header(["class": "doc"]) {
//             // Left column
//             HTML.div(["class": "company"]) {
//                 let titleLeft = nonEmpty(c.name) ?? options.title
//                 HTML.h1 {
//                     HTML.text(escape(titleLeft))
//                 }

//                 if let kvk = c.kvk {
//                     HTML.div(["class": "small"]) {
//                         HTML.text(" \(escape(kvk))")
//                     }
//                 }

//                 if let addr = c.address?.string, !addr.isEmpty {
//                     for line in addr.split(separator: "\n") {
//                         HTML.div(["class": "small"]) {
//                             HTML.text(escape(String(line)))
//                         }
//                     }
//                 }
//             }

//             // Right column
//             HTML.div(["class": "meta"]) {
//                 HTML.div(["class": "title"]) {
//                     HTML.text(escape(options.title))
//                 }
//                 if let sub = options.subtitle {
//                     HTML.div(["class": "subtitle"]) {
//                         HTML.text(escape(sub))
//                     }
//                 }
//             }
//         }
//     }
// }
