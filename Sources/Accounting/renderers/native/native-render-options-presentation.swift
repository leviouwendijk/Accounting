import Foundation

extension NativeRenderOptions {
    @inlinable
    func presentationOptions() -> PresentationPrintOptions {
        .init(
            caption: caption,
            detail: detail,
            showMatchedCodes: false,
            showEntityBreakdown: showEntityBreakdown,
            periodShape: periodShape
        )
    }
    // @inlinable
    // func presentationOptions() -> PresentationPrintOptions {
    //     .init(
    //         caption: presentationCaptionStyle(),
    //         detail: presentationDetailStyle(),
    //         showMatchedCodes: false,
    //         showEntityBreakdown: showEntityBreakdown,
    //         periodShape: periodShape
    //     )
    // }

    // @inlinable
    // func presentationCaptionStyle() -> PresentationCaptionStyle {
    //     switch caption
    //         .trimmingCharacters(in: .whitespacesAndNewlines)
    //         .lowercased()
    //     {
    //     case "label", "name":
    //         return .label

    //     case "label_code", "name_code", "label+code", "name+code":
    //         return .label_code

    //     case "code_label", "code_name", "code+label", "code+name", "code":
    //         return .code_label

    //     default:
    //         return .code_label
    //     }
    // }

    // @inlinable
    // func presentationDetailStyle() -> PresentationDetailStyle {
    //     switch detail
    //         .trimmingCharacters(in: .whitespacesAndNewlines)
    //         .lowercased()
    //     {
    //     case "concise", "minimal", "min":
    //         return .concise

    //     case "standard", "normal", "default", "name":
    //         return .standard

    //     case "verbose", "full", "max":
    //         return .verbose

    //     default:
    //         return .standard
    //     }
    // }
}
