import Foundation
import Primitives

public enum PresentationCaptionStyle: String, Sendable, StringParsableEnum {
    case label
    case label_code
    case code_label
}

public enum PresentationDetailStyle: String, Sendable, StringParsableEnum {
    case concise
    case standard
    case verbose
}

public struct PresentationPrintOptions: Sendable {
    public var caption: PresentationCaptionStyle
    public var detail: PresentationDetailStyle
    public var showMatchedCodes: Bool
    public var showEntityBreakdown: Bool

    public init(
        caption: PresentationCaptionStyle = .label,
        detail: PresentationDetailStyle = .standard,
        showMatchedCodes: Bool = false,
        showEntityBreakdown: Bool = false
    ) {
        self.caption = caption
        self.detail = detail
        self.showMatchedCodes = showMatchedCodes
        self.showEntityBreakdown = showEntityBreakdown
    }
}

extension RGSPrinter {
    @inline(__always)
    static func caption(
        label: String,
        code: String,
        style: PresentationCaptionStyle
    ) -> String {
        switch style {
        case .label:
            return label
        case .label_code:
            return "\(label) [\(code)]"
        case .code_label:
            return "[\(code)] \(label)"
        }
    }

    @inline(__always)
    static func caption(
        for line: RGSBalanceBucketsOutput.Line,
        style: PresentationCaptionStyle
    ) -> String {
        caption(
            label: line.label,
            code: line.code,
            style: style
        )
    }
}
