import Foundation

public struct ECDocumentFile: Sendable {
    public let documents: [ECDocument]

    public init(documents: [ECDocument]) {
        self.documents = documents
    }
}

public struct ECDocument: Sendable {
    public let id: String
    public let kind: ECDocumentKind
    public let title: String?
    public let subtitle: String?
    public let recipient: String?
    public let subjectPrefix: String?
    public let senderName: String?
    public let senderRole: String?
    public let place: String?
    public let date: Date?
    public let periods: [String]
    public let footerLines: [String]
    public let administratorLines: [String]
    public let footerNote: String?
    public let metaRows: [ECDocumentMetaRow]
    public let blocks: [ECDocumentBlock]
    public let assets: ECDocumentAssets?

    public init(
        id: String,
        kind: ECDocumentKind,
        title: String?,
        subtitle: String?,
        recipient: String?,
        subjectPrefix: String?,
        senderName: String?,
        senderRole: String?,
        place: String?,
        date: Date?,
        periods: [String],
        footerLines: [String],
        administratorLines: [String],
        footerNote: String?,
        metaRows: [ECDocumentMetaRow],
        blocks: [ECDocumentBlock],
        assets: ECDocumentAssets?
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.recipient = recipient
        self.subjectPrefix = subjectPrefix
        self.senderName = senderName
        self.senderRole = senderRole
        self.place = place
        self.date = date
        self.periods = periods
        self.footerLines = footerLines
        self.administratorLines = administratorLines
        self.footerNote = footerNote
        self.metaRows = metaRows
        self.blocks = blocks
        self.assets = assets
    }

    public var outputFilename: String {
        "\(id).pdf"
    }

    public var outputHTMLFilename: String {
        "\(id).html"
    }
}

public enum ECDocumentKind: String, Sendable {
    case declaration_of_truthfulness
    case discrepancy_statement
}

public struct ECDocumentMetaRow: Sendable {
    public let label: String
    public let value: String

    public init(
        label: String,
        value: String
    ) {
        self.label = label
        self.value = value
    }
}

public enum ECDocumentBlock: Sendable {
    case section(ECDocumentSection)
    case discrepancy(ECDocumentDiscrepancyBlock)
    case attachments(ECDocumentAttachmentsBlock)
    case signature(ECDocumentSignatureBlock)
}

public struct ECDocumentAssets: Sendable {
    public let signatureImagePath: String?

    public init(signatureImagePath: String?) {
        self.signatureImagePath = signatureImagePath
    }
}

public struct ECDocumentSection: Sendable {
    public let header: String?
    public let paragraphs: [String]
    public let template: String?

    public init(
        header: String?,
        paragraphs: [String],
        template: String? = nil
    ) {
        self.header = header
        self.paragraphs = paragraphs
        self.template = template
    }
}

public struct ECDocumentDiscrepancyBlock: Sendable {
    public let heading: String
    public let label: String?
    public let paragraphs: [String]

    public init(
        heading: String,
        label: String?,
        paragraphs: [String]
    ) {
        self.heading = heading
        self.label = label
        self.paragraphs = paragraphs
    }
}

public struct ECDocumentAttachmentsBlock: Sendable {
    public let title: String?
    public let items: [String]

    public init(
        title: String?,
        items: [String]
    ) {
        self.title = title
        self.items = items
    }
}

public struct ECDocumentSignatureBlock: Sendable {
    public let includeSignatureImage: Bool
    public let includeDate: Bool

    public init(
        includeSignatureImage: Bool,
        includeDate: Bool = true
    ) {
        self.includeSignatureImage = includeSignatureImage
        self.includeDate = includeDate
    }
}
