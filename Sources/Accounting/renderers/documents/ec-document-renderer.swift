import Foundation
import HTML
import CSS
import Writers
import plate

public enum ECDocumentRenderer {
    public static func renderHTML(
        _ document: ECDocument
    ) throws -> String {
        switch document.kind {
        case .declaration_of_truthfulness:
            return try renderTruthfulness(document)
        }
    }

    private static func expandTemplate(
        _ template: String,
        senderName: String,
        senderRole: String,
        recipient: String,
        subjectPrefix: String,
        periodsSentence: String,
        periodPrefix: String,
        date: String
    ) -> String {
        template
            .replacingOccurrences(of: "{{sender_name}}", with: senderName)
            .replacingOccurrences(of: "{{sender_role}}", with: senderRole)
            .replacingOccurrences(of: "{{recipient}}", with: recipient)
            .replacingOccurrences(of: "{{subject_prefix}}", with: subjectPrefix)
            .replacingOccurrences(of: "{{periods_sentence}}", with: periodsSentence)
            .replacingOccurrences(of: "{{period_prefix}}", with: periodPrefix)
            .replacingOccurrences(of: "{{date}}", with: date)
    }

    private static func renderTruthfulness(
        _ document: ECDocument
    ) throws -> String {
        let periods = document.periods.isEmpty
            ? ["1 januari 2025 t/m 31 december 2025"]
            : document.periods

        let date = document.date.map(formatDateNL) ?? formatDateNL(Date())

        let subjectPrefix = document.subjectPrefix ?? "Verklaring betreffende financiële informatie:"
        let recipient = document.recipient ?? "Onbekende ontvanger"
        let senderName = document.senderName ?? "Onbekende afzender"
        let senderRole = document.senderRole ?? "Ondertekenaar"

        let periodLabel = periods.joined(separator: " / ")
        let subject = "\(subjectPrefix) \(periodLabel)"
        let periodsSentence = joinedForSentenceNl(periods)
        let periodPrefix = periods.count == 1 ? "periode" : "periodes"

        let blocks = document.blocks.isEmpty ? defaultBlocks(
            senderName: senderName,
            periodsSentence: periodsSentence,
            periodPrefix: periodPrefix
        ) : document.blocks

        let css = renderStylesheet()

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(["charset": "utf-8"])
                    HTML.meta([
                        "name": "viewport",
                        "content": "width=device-width, initial-scale=1"
                    ])
                    HTML.title(document.title ?? "Verklaring van Financiële Informatie")
                    HTML.style(css)
                }

                HTML.body {
                    HTML.div(["class": "page"]) {
                        HTML.article(["class": "letter"]) {
                            HTML.div(["class": "top-row"]) {
                                HTML.div {
                                    HTML.h1(["class": "letter-title"]) {
                                        HTML.text(document.title ?? "Verklaring van Financiële Informatie")
                                    }

                                    HTML.div(["class": "meta"]) {
                                        metaRow("Datum", date)
                                        metaRow("Aan", recipient)
                                        metaRow("Onderwerp", subject)
                                    }
                                }
                            }

                            for block in blocks {
                                switch block {
                                case .section(let section):
                                    if let header = section.header {
                                        HTML.h2(["class": "section-title"]) {
                                            HTML.text(header)
                                        }
                                    }

                                    if let template = section.template {
                                        HTML.p {
                                            HTML.text(
                                                expandTemplate(
                                                    template,
                                                    senderName: senderName,
                                                    senderRole: senderRole,
                                                    recipient: recipient,
                                                    subjectPrefix: subjectPrefix,
                                                    periodsSentence: periodsSentence,
                                                    periodPrefix: periodPrefix,
                                                    date: date
                                                )
                                            )
                                        }
                                    }

                                    for paragraph in section.paragraphs {
                                        HTML.p {
                                            HTML.text(paragraph)
                                        }
                                    }

                                case .signature(let signature):
                                    HTML.div(["class": "signature-wrap"]) {
                                        if signature.includeSignatureImage,
                                           let rawPath = document.assets?.signatureImagePath,
                                           !rawPath.isEmpty {

                                            let src: String = {
                                                if rawPath.contains("://") {
                                                    return rawPath
                                                }

                                                return URL(fileURLWithPath: rawPath).absoluteString
                                            }()

                                            HTML.img(
                                                src: src,
                                                [
                                                    "alt": "Handtekening",
                                                    "class": "signature-image"
                                                ]
                                            )
                                        }

                                        HTML.div { HTML.text(senderName) }
                                        HTML.div { HTML.text(senderRole) }

                                        if signature.includeDate {
                                            HTML.div { HTML.text(date) }
                                        }
                                    }
                                }
                            }

                            HTML.div(["class": "footer"]) {
                                for line in document.footerLines {
                                    HTML.div(["class": "footer-line"]) {
                                        HTML.text(line)
                                    }
                                }

                                for line in document.administratorLines {
                                    HTML.div(["class": "footer-line"]) {
                                        HTML.text(line)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        return doc.render()
    }

    private static func defaultBlocks(
        senderName: String,
        periodsSentence: String,
        periodPrefix: String
    ) -> [ECDocumentBlock] {
        [
            .section(
                ECDocumentSection(
                    header: "Periode in kwestie",
                    paragraphs: [
                        "Hierbij verklaar ik, \(senderName), autonoom de boekhouding te hebben verzorgd voor (De) Hondenmeesters over de \(periodPrefix) \(periodsSentence). Deze verklaring heeft betrekking op de meegeleverde documentatie, waaronder balans en winst-en-verliesrekening."
                    ]
                )
            ),
            .section(
                ECDocumentSection(
                    header: "Verantwoordelijkheid voor de financiële informatie",
                    paragraphs: [
                        "Als beheerder van de boekhouding ben ik verantwoordelijk voor het opstellen van de financiële informatie in overeenstemming met Nederlandse GAAP (uitgaande van het stelsel zoals opgemaakt in het RGS), en voor het handhaven van adequate administratieve controle die ervoor zorgt dat de financiële informatie vrij is van materiële misverstanden, hetzij door fraude of fouten.",
                        "De door mij opgestelde financiële informatie is naar mijn beste weten en overtuiging nauwkeurig en een getrouwe weergave van de werkelijke financiële situatie van (De) Hondenmeesters per de genoemde datum."
                    ]
                )
            ),
            .section(
                ECDocumentSection(
                    header: "Bevestiging van juistheid",
                    paragraphs: [
                        "Ik bevestig hierbij dat naar mijn beste weten de financiële informatie zoals gepresenteerd correct en volledig is."
                    ]
                )
            ),
            .signature(
                ECDocumentSignatureBlock(includeSignatureImage: true)
            )
        ]
    }

    private static func metaRow(
        _ label: String,
        _ value: String
    ) -> any HTMLNode {
        HTML.div(["class": "meta-row"]) {
            HTML.span(["class": "meta-label"]) {
                HTML.text(label)
            }
            HTML.span(["class": "meta-value"]) {
                HTML.text(value)
            }
        }
    }

    private static func formatDateNL(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nl_NL")
        df.timeZone = TimeZone(identifier: "Europe/Amsterdam")
        df.dateFormat = "dd/MM/yyyy"
        return df.string(from: date)
    }

    private static func joinedForSentenceNl(_ items: [String]) -> String {
        switch items.count {
        case 0:
            return ""
        case 1:
            return items[0]
        case 2:
            return items[0] + " en " + items[1]
        default:
            let head = items.dropLast().joined(separator: ", ")
            return head + " en " + items.last!
        }
    }

    private static func renderStylesheet() -> String {
        let sheet = CSSStyleSheet(
            rules: [
                CSS.rule(":root",
                    CSS.decl("--ink", "#111111"),
                    CSS.decl("--muted", "#555555"),
                    CSS.decl("--paper", "#ffffff")
                ),
                CSS.rule("body",
                    CSS.decl("margin", "0"),
                    CSS.decl("background", "#ffffff"),
                    CSS.decl("color", "var(--ink)"),
                    CSS.decl("font-family", "\"Times New Roman\", Times, serif"),
                    CSS.decl("font-size", "12pt"),
                    CSS.decl("line-height", "1.45")
                ),
                CSS.rule(".page",
                    CSS.decl("padding", "0")
                ),
                CSS.rule(".letter",
                    CSS.decl("width", "100%"),
                    CSS.decl("max-width", "none"),
                    CSS.decl("margin", "0"),
                    CSS.decl("background", "#ffffff"),
                    CSS.decl("border", "none"),
                    CSS.decl("border-radius", "0"),
                    CSS.decl("box-shadow", "none"),
                    CSS.decl("padding", "0")
                ),
                CSS.rule(".top-row",
                    CSS.decl("display", "flex"),
                    CSS.decl("justify-content", "space-between"),
                    CSS.decl("gap", "18px"),
                    CSS.decl("align-items", "flex-start")
                ),
                CSS.rule(".letter-title",
                    CSS.decl("margin", "0 0 6px 0"),
                    CSS.decl("font-size", "18px"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".meta",
                    CSS.decl("display", "grid"),
                    CSS.decl("gap", "8px"),
                    CSS.decl("margin", "18px 0 24px 0")
                ),
                CSS.rule(".meta-row",
                    CSS.decl("display", "flex"),
                    CSS.decl("gap", "10px")
                ),
                CSS.rule(".meta-label",
                    CSS.decl("min-width", "100px"),
                    CSS.decl("font-weight", "600"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".section-title",
                    CSS.decl("margin", "28px 0 10px 0"),
                    CSS.decl("font-size", "16px"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".signature-wrap",
                    CSS.decl("margin-top", "30px")
                ),
                CSS.rule(".signature-image-placeholder",
                    CSS.decl("margin-bottom", "8px"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".footer",
                    CSS.decl("margin-top", "36px"),
                    CSS.decl("padding-top", "16px"),
                    CSS.decl("border-top", "1px solid var(--border)"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".footer-line",
                    CSS.decl("margin", "3px 0")
                )
            ]
        )

        return sheet.render()
    }
}

