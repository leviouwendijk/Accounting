import Foundation
import Terminal

public enum ECSourceTerminalRenderer {}

extension ECSourceTerminalRenderer {
    public typealias Options = ECSourcePresentationOptions

    public static func render(
        files: [ECSourceFile],
        options: Options = .init()
    ) -> String {
        let document = ECSourcePresenter.present(
            files: files,
            options: options
        )

        return render(
            document: document,
            options: options
        )
    }

    public static func render(
        document: ECSourceDocument,
        options: Options = .init()
    ) -> String {
        ECSourceRendererShared.makeOutput(
            document: document,
            options: options,
            renderTitle: styledTitle,
            renderSubtitle: styledSubtitle,
            renderFilePath: styledFilePath,
            renderFileMeta: styledFileMeta,
            renderRule: styledRule,
            renderBlockCaption: styledBlockCaption,
            renderLine: renderedLine
        )
    }

    private static func renderedLine(
        _ line: ECSourcePresentedLine,
        showLineNumbers: Bool,
        lineNumberWidth: Int
    ) -> String {
        let text = renderedFragments(line.fragments)

        guard showLineNumbers else {
            return text
        }

        let number = String(line.number)
        let padding = String(
            repeating: " ",
            count: max(0, lineNumberWidth - number.count)
        )

        let gutter = "\(padding)\(number) │".ansi(.brightBlack)
        return "\(gutter) \(text)"
    }

    private static func renderedFragments(
        _ fragments: [ECSyntaxFragment]
    ) -> String {
        fragments.map { fragment in
            styledFragment(fragment.text, kind: fragment.kind)
        }
        .joined()
    }

    private static func styledFragment(
        _ text: String,
        kind: ECSyntaxKind
    ) -> String {
        switch kind {
        case .plain:
            return text

        case .keyword:
            return text.ansi(.magenta, .bold)

        case .identifier:
            return text

        case .account:
            return text.ansi(.yellow, .bold)

        case .entity:
            return text.ansi(.brightYellow, .bold)

        case .number:
            return text.ansi(.yellow)

        case .string:
            return text.ansi(.green)

        case .date:
            return text.ansi(.cyan)

        case .punctuation:
            return text.ansi(.brightBlack)

        case .comment:
            return text.ansi(.brightBlack, .italic)
        }
    }

    private static func styledTitle(
        _ text: String
    ) -> String {
        text.ansi(.white, .bold)
    }

    private static func styledSubtitle(
        _ text: String
    ) -> String {
        text.ansi(.brightBlack)
    }

    private static func styledFilePath(
        _ text: String
    ) -> String {
        text.ansi(.brightBlue, .bold)
    }

    private static func styledFileMeta(
        _ text: String
    ) -> String {
        text.ansi(.brightBlack)
    }

    private static func styledBlockCaption(
        _ text: String
    ) -> String {
        text.ansi(.brightWhite, .bold)
    }

    private static func styledRule(
        _ length: Int
    ) -> String {
        String(
            repeating: "─",
            count: max(1, length)
        )
        .ansi(.brightBlack)
    }
}
