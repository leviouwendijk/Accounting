import Foundation
import HTML
import CSS
import Writers

extension ECDocumentRenderer {
    public static func expandTemplate(
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

    public static func renderTruthfulness(
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

                                case .discrepancy(let discrepancy):
                                    HTML.h2(["class": "section-title"]) {
                                        HTML.text(discrepancy.heading)
                                    }

                                    if let label = discrepancy.label, !label.isEmpty {
                                        HTML.p {
                                            HTML.text(label)
                                        }
                                    }

                                    for paragraph in discrepancy.paragraphs {
                                        HTML.p {
                                            HTML.text(paragraph)
                                        }
                                    }

                                case .attachments(let attachments):
                                    if let title = attachments.title, !title.isEmpty {
                                        HTML.h2(["class": "section-title"]) {
                                            HTML.text(title)
                                        }
                                    }

                                    HTML.ul {
                                        for item in attachments.items {
                                            HTML.li {
                                                HTML.text(item)
                                            }
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

                            if !document.footerLines.isEmpty || !document.administratorLines.isEmpty {
                                HTML.div(["class": "footer-block"]) {
                                    for line in document.footerLines {
                                        HTML.div(["class": "footer-line"]) {
                                            HTML.text(line)
                                        }
                                    }

                                    if !document.administratorLines.isEmpty {
                                        HTML.hr(["class": "footer-separator"])

                                        for line in document.administratorLines {
                                            HTML.div(["class": "administrator-line"]) {
                                                HTML.text(line)
                                            }
                                        }
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

    public static func defaultBlocks(
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

    public static func metaRow(
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

    public static func formatDateNL(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nl_NL")
        df.timeZone = TimeZone(identifier: "Europe/Amsterdam")
        df.dateFormat = "dd/MM/yyyy"
        return df.string(from: date)
    }

    public static func joinedForSentenceNl(_ items: [String]) -> String {
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

    public static func renderStylesheet() -> String {
        let sheet = CSSStyleSheet(
            rules: [
                CSS.rule(":root",
                    CSS.decl("--ink", "#111111"),
                    // CSS.decl("--muted", "#555555"),
                    CSS.decl("--paper", "#ffffff"),
                    CSS.decl("--muted", "#6b7280"),
                    CSS.decl("--border", "#e5e7eb"),
                ),
                CSS.rule("body",
                    CSS.decl("margin", "0"),
                    CSS.decl("background", "#ffffff"),
                    CSS.decl("color", "var(--ink)"),
                    CSS.decl("font-family", "\"Times New Roman\", Times, serif"),
                    CSS.decl("font-size", "11pt"),
                    CSS.decl("line-height", "1.38")
                ),
                CSS.rule(".letter-title",
                    CSS.decl("margin", "0 0 6px 0"),
                    CSS.decl("font-size", "16px"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".section-title",
                    CSS.decl("margin", "24px 0 8px 0"),
                    CSS.decl("font-size", "14px"),
                    CSS.decl("font-weight", "700")
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
                CSS.rule(".signature-wrap",
                    CSS.decl("margin-top", "30px")
                ),
                CSS.rule(".signature-image",
                    CSS.decl("display", "block"),
                    CSS.decl("max-width", "220px"),
                    CSS.decl("width", "220px"),
                    CSS.decl("height", "auto"),
                    CSS.decl("max-height", "64px"),
                    CSS.decl("object-fit", "contain"),
                    CSS.decl("margin-bottom", "8px")
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
                CSS.rule(".footer-block",
                    CSS.decl("margin-top", "24px"),
                    CSS.decl("font-size", "10pt"),
                    CSS.decl("line-height", "1.28"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".footer-line",
                    CSS.decl("margin", "0 0 2px 0"),
                    CSS.decl("color", "inherit")
                ),
                CSS.rule(".footer-separator",
                    CSS.decl("border", "none"),
                    CSS.decl("border-top", "1px solid var(--border)"),
                    CSS.decl("margin", "12px 0 10px 0")
                ),
                CSS.rule(".administrator-line",
                    CSS.decl("margin", "0 0 2px 0"),
                    CSS.decl("color", "inherit")
                )
            ]
        )

        return sheet.render()
    }
}

extension ECDocumentRenderer {
    public static func renderDiscrepancyStatement(
        _ document: ECDocument
    ) throws -> String {
        let date = document.date.map(formatDateNL) ?? formatDateNL(Date())
        let title = document.title ?? "Toelichting inkomsten-aanslag"
        let subtitle = document.subtitle ?? ""
        let senderName = document.senderName ?? "Onbekende afzender"
        let senderRole = document.senderRole ?? "Ondertekenaar"
        let place = document.place ?? "____________________________"

        let metaRows: [ECDocumentMetaRow] = {
            if !document.metaRows.isEmpty {
                return document.metaRows
            }

            return [
                ECDocumentMetaRow(label: "Datum", value: date)
            ]
        }()

        let css = renderDiscrepancyStylesheet()

        let doc = HTML.document {
            HTML.html(["lang": "nl"]) {
                HTML.head {
                    HTML.meta(["charset": "utf-8"])
                    HTML.meta([
                        "name": "viewport",
                        "content": "width=device-width, initial-scale=1"
                    ])
                    HTML.title(title)
                    HTML.style(css)
                }

                HTML.body {
                    HTML.div(["class": "page"]) {
                        HTML.article(["class": "discrepancy-doc"]) {
                            HTML.header {
                                HTML.h1(["class": "doc-title"]) {
                                    HTML.text(title)
                                }

                                if !subtitle.isEmpty {
                                    HTML.p(["class": "doc-sub"]) {
                                        HTML.text(subtitle)
                                    }
                                }
                            }

                            if !metaRows.isEmpty {
                                HTML.div(["class": "kv-block"]) {
                                    for row in metaRows {
                                        HTML.div(["class": "kv-row"]) {
                                            HTML.span(["class": "kv-label"]) {
                                                HTML.text("\(row.label):")
                                            }
                                            HTML.span(["class": "kv-value"]) {
                                                HTML.text(row.value)
                                            }
                                        }
                                    }
                                }
                            }

                            for block in document.blocks {
                                switch block {
                                case .section(let section):
                                    if let header = section.header {
                                        HTML.h2(["class": "section-title"]) {
                                            HTML.text(header)
                                        }
                                    }

                                    if let template = section.template {
                                        HTML.p(["class": "para"]) {
                                            HTML.text(
                                                expandTemplate(
                                                    template,
                                                    senderName: senderName,
                                                    senderRole: senderRole,
                                                    recipient: document.recipient ?? "",
                                                    subjectPrefix: document.subjectPrefix ?? "",
                                                    periodsSentence: joinedForSentenceNl(document.periods),
                                                    periodPrefix: document.periods.count == 1 ? "periode" : "periodes",
                                                    date: date
                                                )
                                            )
                                        }
                                    }

                                    for paragraph in section.paragraphs {
                                        HTML.p(["class": "para"]) {
                                            HTML.text(paragraph)
                                        }
                                    }

                                case .discrepancy(let discrepancy):
                                    HTML.p(["class": "heading"]) {
                                        HTML.text(discrepancy.heading)
                                    }

                                    HTML.div(["class": "indent"]) {
                                        if let label = discrepancy.label, !label.isEmpty {
                                            HTML.span(["class": "label"]) {
                                                HTML.text(label)
                                            }
                                        }

                                        for paragraph in discrepancy.paragraphs {
                                            HTML.p(["class": "para"]) {
                                                HTML.text(paragraph)
                                            }
                                        }
                                    }

                                case .attachments(let attachments):
                                    HTML.div(["class": "attachments"]) {
                                        if let title = attachments.title, !title.isEmpty {
                                            HTML.p(["class": "attachments-title"]) {
                                                HTML.text(title)
                                            }
                                        }

                                        HTML.ul {
                                            for item in attachments.items {
                                                HTML.li {
                                                    HTML.text(item)
                                                }
                                            }
                                        }
                                    }

                                case .signature(let signature):
                                    HTML.div(["class": "sign"]) {
                                        HTML.div(["class": "box"]) {
                                            HTML.strong {
                                                HTML.text("Ondertekening verantwoordelijke")
                                            }

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

                                            HTML.div(["class": "sig-line"]) {}
                                            HTML.div { HTML.text("Naam: \(senderName)") }
                                            HTML.div { HTML.text("Rol: \(senderRole)") }
                                        }

                                        HTML.div(["class": "box"]) {
                                            HTML.strong {
                                                HTML.text("Plaats / Datum")
                                            }

                                            HTML.div {
                                                HTML.text("Plaats: \(place)")
                                            }

                                            HTML.div {
                                                HTML.text(
                                                    signature.includeDate
                                                        ? "Datum: \(date)"
                                                        : "Datum: ______ / ____ / ____"
                                                )
                                            }
                                        }
                                    }
                                }
                            }

                            if let footerNote = document.footerNote, !footerNote.isEmpty {
                                HTML.div(["class": "muted-footer"]) {
                                    HTML.text(footerNote)
                                }
                            }
                        }
                    }
                }
            }
        }

        return doc.render()
    }

    public static func renderDiscrepancyStylesheet() -> String {
        let sheet = CSSStyleSheet(
            rules: [
                CSS.rule(":root",
                    CSS.decl("--ink", "#111111"),
                    CSS.decl("--muted", "#6b7280"),
                    CSS.decl("--line", "#d9dee4"),
                    CSS.decl("--paper", "#ffffff")
                ),
                CSS.rule("body",
                    CSS.decl("margin", "0"),
                    CSS.decl("background", "#ffffff"),
                    CSS.decl("color", "var(--ink)"),
                    CSS.decl("font-family", "\"Times New Roman\", Times, serif"),
                    CSS.decl("font-size", "11pt"),
                    CSS.decl("line-height", "1.4")
                ),
                CSS.rule(".page",
                    CSS.decl("padding", "0")
                ),
                CSS.rule(".doc-title",
                    CSS.decl("margin", "0 0 4px 0"),
                    CSS.decl("font-size", "18px"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".doc-sub",
                    CSS.decl("margin", "0 0 16px 0"),
                    CSS.decl("font-size", "11pt"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".discrepancy-doc",
                    CSS.decl("width", "100%"),
                    CSS.decl("margin", "0"),
                    CSS.decl("padding", "0")
                ),
                CSS.rule(".kv-block",
                    CSS.decl("margin", "0 0 14px 0"),
                    CSS.decl("font-size", "10.5pt"),
                    CSS.decl("color", "var(--muted)")
                ),
                CSS.rule(".kv-row",
                    CSS.decl("margin", "0 0 4px 0")
                ),
                CSS.rule(".kv-label",
                    CSS.decl("font-weight", "700"),
                    CSS.decl("color", "var(--ink)")
                ),
                CSS.rule(".heading",
                    CSS.decl("margin", "16px 0 6px 0"),
                    CSS.decl("font-size", "12pt"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".indent",
                    CSS.decl("padding-left", "12px"),
                    CSS.decl("border-left", "2px solid var(--line)"),
                    CSS.decl("margin", "0 0 12px 0")
                ),
                CSS.rule(".label",
                    CSS.decl("display", "block"),
                    CSS.decl("font-weight", "700"),
                    CSS.decl("margin-bottom", "4px")
                ),
                CSS.rule(".para",
                    CSS.decl("margin", "0 0 10px 0")
                ),
                CSS.rule(".attachments",
                    CSS.decl("margin-top", "14px"),
                    CSS.decl("padding", "10px 12px"),
                    CSS.decl("border", "1px solid var(--line)"),
                    CSS.decl("border-radius", "8px")
                ),
                CSS.rule(".attachments-title",
                    CSS.decl("margin", "0 0 6px 0"),
                    CSS.decl("font-weight", "700")
                ),
                CSS.rule(".sign",
                    CSS.decl("margin-top", "18px"),
                    CSS.decl("display", "grid"),
                    CSS.decl("grid-template-columns", "1fr 1fr"),
                    CSS.decl("gap", "12px")
                ),
                CSS.rule(".box",
                    CSS.decl("border", "1px dashed var(--line)"),
                    CSS.decl("border-radius", "8px"),
                    CSS.decl("padding", "10px 12px"),
                    CSS.decl("min-height", "72px")
                ),
                CSS.rule(".signature-image",
                    CSS.decl("display", "block"),
                    CSS.decl("max-width", "220px"),
                    CSS.decl("width", "220px"),
                    CSS.decl("height", "auto"),
                    CSS.decl("max-height", "64px"),
                    CSS.decl("object-fit", "contain"),
                    CSS.decl("margin", "8px 0 8px 0")
                ),
                CSS.rule(".sig-line",
                    CSS.decl("margin", "8px 0 8px 0"),
                    CSS.decl("width", "220px"),
                    CSS.decl("max-width", "100%"),
                    CSS.decl("border-bottom", "1px solid var(--ink)")
                ),
                CSS.rule(".muted-footer",
                    CSS.decl("margin-top", "14px"),
                    CSS.decl("color", "var(--muted)"),
                    CSS.decl("font-size", "10pt")
                ),
                CSS.rule("@page",
                    CSS.decl("size", "A4"),
                    CSS.decl("margin", "20mm 18mm 20mm 18mm")
                ),
            ]
        )

        return sheet.render()
    }
}
