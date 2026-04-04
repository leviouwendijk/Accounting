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

                                    HTML.div(["class": "attachments-block"]) {
                                        for group in attachments.groups {
                                            if !group.items.isEmpty {
                                                HTML.div(["class": "attachments-group"]) {
                                                    HTML.ul(["class": "attachments-list"]) {
                                                        for item in group.items {
                                                            HTML.li {
                                                                HTML.text(item)
                                                            }
                                                        }
                                                    }
                                                }
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
                                let hasFooter = !document.footerLines.isEmpty
                                let hasAdministrator = !document.administratorLines.isEmpty

                                HTML.div([
                                    "class": hasFooter && hasAdministrator
                                        ? "footer-block has-divider"
                                        : "footer-block"
                                ]) {
                                    if hasFooter {
                                        HTML.div(["class": "footer-column"]) {
                                            for line in document.footerLines {
                                                HTML.div(["class": "footer-line"]) {
                                                    HTML.text(line)
                                                }
                                            }
                                        }
                                    }

                                    if hasAdministrator {
                                        HTML.div([
                                            "class": hasFooter
                                                ? "footer-column administrator-column"
                                                : "footer-column"
                                        ]) {
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
        CSSStyleSheet
            .merged([
                Style.common(),
                Style.truthfulness()
            ])
            .render()
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

                                        for group in attachments.groups {
                                            if !group.items.isEmpty {
                                                HTML.div(["class": "attachments-group"]) {
                                                    HTML.ul(["class": "attachments-list"]) {
                                                        for item in group.items {
                                                            HTML.li {
                                                                HTML.text(item)
                                                            }
                                                        }
                                                    }
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

                            if !document.footerLines.isEmpty || !document.administratorLines.isEmpty {
                                let hasFooter = !document.footerLines.isEmpty
                                let hasAdministrator = !document.administratorLines.isEmpty

                                HTML.div([
                                    "class": hasFooter && hasAdministrator
                                        ? "footer-block has-divider"
                                        : "footer-block"
                                ]) {
                                    if hasFooter {
                                        HTML.div(["class": "footer-column"]) {
                                            for line in document.footerLines {
                                                HTML.div(["class": "footer-line"]) {
                                                    HTML.text(line)
                                                }
                                            }
                                        }
                                    }

                                    if hasAdministrator {
                                        HTML.div([
                                            "class": hasFooter
                                                ? "footer-column administrator-column"
                                                : "footer-column"
                                        ]) {
                                            for line in document.administratorLines {
                                                HTML.div(["class": "administrator-line"]) {
                                                    HTML.text(line)
                                                }
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
        CSSStyleSheet
            .merged([
                Style.common(),
                Style.discrepancy()
            ])
            .render()
    }
}

extension ECDocumentRenderer {
    public static func renderGenericDocument(
        _ document: ECDocument
    ) throws -> String {
        let date = document.date.map(formatDateNL) ?? formatDateNL(Date())
        let title = document.title ?? "Document"
        let subtitle = document.subtitle ?? ""
        let senderName = document.senderName ?? "Onbekende afzender"
        let senderRole = document.senderRole ?? "Ondertekenaar"

        let metaRows = genericMetaRows(
            for: document,
            date: date
        )

        let css = renderGenericStylesheet()

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
                        HTML.article(["class": "generic-doc"]) {
                            HTML.header(["class": "doc-header"]) {
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
                                    if let header = section.header, !header.isEmpty {
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
                                    HTML.h2(["class": "section-title"]) {
                                        HTML.text(discrepancy.heading)
                                    }

                                    if let label = discrepancy.label, !label.isEmpty {
                                        HTML.p(["class": "para"]) {
                                            HTML.text(label)
                                        }
                                    }

                                    for paragraph in discrepancy.paragraphs {
                                        HTML.p(["class": "para"]) {
                                            HTML.text(paragraph)
                                        }
                                    }

                                case .attachments(let attachments):
                                    if let title = attachments.title, !title.isEmpty {
                                        HTML.h2(["class": "section-title"]) {
                                            HTML.text(title)
                                        }
                                    }

                                    HTML.div(["class": "attachments-block"]) {
                                        for group in attachments.groups {
                                            if !group.items.isEmpty {
                                                HTML.div(["class": "attachments-group"]) {
                                                    HTML.ul(["class": "attachments-list"]) {
                                                        for item in group.items {
                                                            HTML.li {
                                                                HTML.text(item)
                                                            }
                                                        }
                                                    }
                                                }
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

                                        HTML.div {
                                            HTML.text(senderName)
                                        }

                                        HTML.div {
                                            HTML.text(senderRole)
                                        }

                                        if signature.includeDate {
                                            HTML.div {
                                                HTML.text(date)
                                            }
                                        }
                                    }
                                }
                            }

                            if !document.footerLines.isEmpty || !document.administratorLines.isEmpty {
                                let hasFooter = !document.footerLines.isEmpty
                                let hasAdministrator = !document.administratorLines.isEmpty

                                HTML.footer(["class": "doc-footer"]) {
                                    if hasFooter {
                                        HTML.div(["class": "footer-col"]) {
                                            for line in document.footerLines {
                                                HTML.div(["class": "footer-line"]) {
                                                    HTML.text(line)
                                                }
                                            }
                                        }
                                    }

                                    if hasAdministrator {
                                        HTML.div(["class": "footer-col"]) {
                                            for line in document.administratorLines {
                                                HTML.div(["class": "footer-line"]) {
                                                    HTML.text(line)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if let footerNote = document.footerNote, !footerNote.isEmpty {
                                HTML.p(["class": "footer-note"]) {
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

    public static func genericMetaRows(
        for document: ECDocument,
        date: String
    ) -> [ECDocumentMetaRow] {
        var rows: [ECDocumentMetaRow] = [
            .init(label: "Datum", value: date)
        ]

        if let recipient = document.recipient, !recipient.isEmpty {
            rows.append(
                .init(label: "Aan", value: recipient)
            )
        }

        if let subjectPrefix = document.subjectPrefix, !subjectPrefix.isEmpty {
            rows.append(
                .init(label: "Onderwerp", value: subjectPrefix)
            )
        }

        if let place = document.place, !place.isEmpty {
            rows.append(
                .init(label: "Plaats", value: place)
            )
        }

        if !document.periods.isEmpty {
            rows.append(
                .init(
                    label: "Periode",
                    value: joinedForSentenceNl(document.periods)
                )
            )
        }

        if !document.metaRows.isEmpty {
            rows.append(contentsOf: document.metaRows)
        }

        return rows
    }

    public static func renderGenericStylesheet() -> String {
        CSSStyleSheet
            .merged([
                Style.common(),
                Style.discrepancy()
            ])
            .render()
    }
}
